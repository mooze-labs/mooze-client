import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import 'address_controller_provider.dart';
import 'address_provider.dart';
import 'amount_detection_provider.dart';
import 'detected_amount_provider.dart';
import 'network_detection_provider.dart';
import 'qr_validation_service.dart';
import 'selected_asset_provider.dart';
import 'send_validation_controller.dart';

/// Applies a scanned, pasted or deep-linked payment request (plain address,
/// BIP21 `bitcoin:` URI or `liquidnetwork:` URI) to the send-funds form.
///
/// One entry point for every source so the QR scanner, the clipboard paste
/// button, the clipboard suggestion banner and incoming deep links all behave
/// the same: validate, keep the full URI in [addressStateProvider] (so the
/// amount and asset detection keep working), show only the bare address in
/// the text field, and switch the selected asset to the detected network.
class PaymentRequestApplier {
  PaymentRequestApplier._();

  static const _uriPrefixes = ['bitcoin:', 'liquidnetwork:', 'liquid:'];

  /// Validates [raw] and, when valid, writes it into the send form.
  ///
  /// Returns the validation result. `isValid == false` means nothing was
  /// applied and the caller should surface `result.localize(context)`.
  static QrValidationResult apply(WidgetRef ref, String raw) {
    final result = QrValidationService.validateQrData(raw.trim());
    if (!result.isValid) return result;

    final cleaned = result.cleanedData ?? raw.trim();
    ref.read(addressStateProvider.notifier).state = cleaned;

    final controller = ref.read(addressControllerProvider);
    final display = displayAddress(cleaned);
    controller.text = display;
    controller.selection = TextSelection.collapsed(offset: display.length);

    ref.invalidate(detectedAmountProvider);
    autoSwitchAsset(ref, cleaned);
    ref.read(sendValidationControllerProvider.notifier).validateTransaction();
    return result;
  }

  /// Strips a BIP21-style scheme and query so only the address is shown.
  static String displayAddress(String data) {
    final lower = data.toLowerCase();
    if (!_uriPrefixes.any(lower.startsWith)) return data;
    try {
      return Uri.parse(data).path;
    } catch (_) {
      return data;
    }
  }

  /// Switches the selected asset to match the network found in [data].
  ///
  /// A BIP21 asset hint wins. Otherwise a Bitcoin address selects BTC and a
  /// Liquid address selects L-BTC, but only when the current selection is
  /// already a native coin, so a user who picked a Liquid token keeps it.
  static void autoSwitchAsset(WidgetRef ref, String data) {
    if (data.isEmpty) return;

    final detected = AmountDetectionService.detectAmount(data);
    if (detected.asset != null) {
      ref.read(selectedAssetProvider.notifier).state = detected.asset!;
      return;
    }

    final networkType = NetworkDetectionService.detectNetworkType(data);
    final current = ref.read(selectedAssetProvider);
    if (current != Asset.btc && current != Asset.lbtc) return;

    final next = switch (networkType) {
      NetworkType.bitcoin => Asset.btc,
      NetworkType.liquid => Asset.lbtc,
      NetworkType.unknown => null,
    };
    if (next != null && next != current) {
      ref.read(selectedAssetProvider.notifier).state = next;
    }
  }
}
