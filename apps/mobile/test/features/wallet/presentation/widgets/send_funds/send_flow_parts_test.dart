import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/send_flow_parts.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';

import '../../../../../shared/test_app.dart';

const _address = 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq';

void main() {
  group('shortenMiddle', () {
    test('keeps the start and the end of a long value', () {
      expect(
        shortenMiddle(_address),
        '${_address.substring(0, 10)}…'
        '${_address.substring(_address.length - 10)}',
      );
    });

    test('keeps a short value as it is', () {
      expect(shortenMiddle('lq1short'), 'lq1short');
    });
  });

  group('SendRecipient', () {
    testWidgets('a tap shows the full address and a second tap shortens it', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          const Scaffold(
            body: SendRecipient(
              label: 'Destino',
              address: _address,
              network: NetworkType.bitcoin,
            ),
          ),
        ),
      );

      expect(find.text(shortenMiddle(_address)), findsOneWidget);
      expect(find.text(_address), findsNothing);

      await tester.tap(find.text(shortenMiddle(_address)));
      await tester.pumpAndSettle();
      expect(find.text(_address), findsOneWidget);

      await tester.tap(find.text(_address));
      await tester.pumpAndSettle();
      expect(find.text(shortenMiddle(_address)), findsOneWidget);
    });

    testWidgets('screen readers get the full address', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrapForTest(
          const Scaffold(
            body: SendRecipient(label: 'Destino', address: _address),
          ),
        ),
      );

      final address = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.value == _address,
      );
      expect(address, findsOneWidget);
      final node = tester.getSemantics(address);
      expect(node.label, 'Destino');
      expect(node.value, _address);
      handle.dispose();
    });

    testWidgets('the copy button puts the full address in the clipboard', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(
        wrapForTest(
          const Scaffold(
            body: SendRecipient(label: 'Destino', address: _address),
          ),
        ),
      );
      await tester.tap(find.byType(SendCopyButton));
      await tester.pump();

      expect(copied, _address);
      // The check stays for two seconds, then the copy icon returns.
      await tester.pump(const Duration(seconds: 3));
    });
  });

  testWidgets('the summary is one glass panel without a backdrop blur', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        const Scaffold(
          body: SendSummaryPanel(
            rows: [
              SendSummaryRow(label: 'Taxa', value: '26 sats'),
              SendSummaryRow(
                label: 'Total',
                value: '1026 sats',
                highlight: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(GlassPanel), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('26 sats'), findsOneWidget);
    expect(find.text('1026 sats'), findsOneWidget);
  });
}
