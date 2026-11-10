import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/domain/services/address_chain_detector.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/controllers/address_ownership_controller.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/widgets/address_ownership_result.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/backdrop_page_scaffold.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

const Duration _kVerifyDebounce = Duration(milliseconds: 500);

/// Heuristic minimum length below which we consider input incomplete and
/// avoid firing the (relatively expensive) ownership probe. Real addresses
/// are well above this threshold.
const int _kMinAddressLength = 14;

class AddressOwnershipScreen extends ConsumerStatefulWidget {
  const AddressOwnershipScreen({super.key});

  @override
  ConsumerState<AddressOwnershipScreen> createState() =>
      _AddressOwnershipScreenState();
}

class _AddressOwnershipScreenState
    extends ConsumerState<AddressOwnershipScreen> {
  final _controller = TextEditingController();
  final _detector = const AddressChainDetector();
  final _scrollController = ScrollController();
  final _resultKey = GlobalKey();

  Timer? _debounce;
  String _lastVerified = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    _debounce?.cancel();
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      _lastVerified = '';
      ref.read(addressOwnershipControllerProvider.notifier).reset();
      return;
    }
    if (!_isFormatPlausible(raw)) {
      _lastVerified = '';
      ref.read(addressOwnershipControllerProvider.notifier).reset();
      return;
    }
    _debounce = Timer(_kVerifyDebounce, () {
      if (!mounted) return;
      final input = _controller.text.trim();
      if (input.isEmpty || input == _lastVerified) return;
      _lastVerified = input;
      ref
          .read(addressOwnershipControllerProvider.notifier)
          .verify(input)
          .then((_) => _scrollToResult());
    });
  }

  bool _isFormatPlausible(String input) {
    final cleaned = _detector.stripUriScheme(input);
    if (cleaned.length < _kMinAddressLength) return false;
    return _detector.detect(cleaned).isNotEmpty;
  }

  AddressChain? _detectedChain(String input) {
    final cleaned = _detector.stripUriScheme(input);
    if (cleaned.isEmpty) return null;
    final chains = _detector.detect(cleaned);
    if (chains.length == 1) return chains.first;
    return null;
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    _showFeedback(t.address_ownership_paste_feedback);
  }

  void _clear() {
    if (_controller.text.isEmpty) return;
    _controller.clear();
    _debounce?.cancel();
    _lastVerified = '';
    ref.read(addressOwnershipControllerProvider.notifier).reset();
    final t = AppLocalizations.of(context);
    _showFeedback(t.address_ownership_clear_feedback);
  }

  void _showFeedback(String message) {
    AppSnackBar.info(context, message);
  }

  void _scrollToResult() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: Motion.of(context, Motion.durationEmphasis),
        curve: Motion.curveMove,
        alignment: 0.1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(addressOwnershipControllerProvider);
    final colors = context.colors;
    final tt = context.textTheme;
    final hairline = AppSurfaces.hairline(context);
    OutlineInputBorder frame(Color color, double width) => OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: color, width: width),
    );
    final codeStyle = tt.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      // iOS has no font named "monospace", so it takes the fallback.
      fontFamilyFallback: const ['Menlo', 'Courier'],
      color: colors.textPrimary,
    );

    final raw = _controller.text.trim();
    final hasInput = raw.isNotEmpty;
    final cleaned = _detector.stripUriScheme(raw);
    final detectedChain = _detectedChain(raw);
    final invalidFormat =
        hasInput &&
        cleaned.length >= _kMinAddressLength &&
        _detector.detect(cleaned).isEmpty;

    return BackdropPageScaffold(
      title: t.address_ownership_title,
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          BackdropPageScaffold.gutter,
          12,
          BackdropPageScaffold.gutter,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.address_ownership_description,
                    style: tt.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.address_ownership_subtitle,
                    style: tt.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                final input = _controller.text.trim();
                if (input.isEmpty || !_isFormatPlausible(input)) return;
                _debounce?.cancel();
                _lastVerified = input;
                ref
                    .read(addressOwnershipControllerProvider.notifier)
                    .verify(input)
                    .then((_) => _scrollToResult());
              },
              cursorColor: colors.primaryColor,
              style: codeStyle,
              decoration: InputDecoration(
                hintText: t.address_ownership_input_hint,
                hintStyle: codeStyle?.copyWith(color: colors.textTertiary),
                filled: true,
                fillColor: GlassStyle.of(context).lensFill,
                border: frame(hairline, 1),
                enabledBorder: frame(hairline, 1),
                focusedBorder: frame(colors.primaryColor, 1.5),
                contentPadding: const EdgeInsets.fromLTRB(14, 15, 96, 15),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasInput)
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: colors.textSecondary,
                        ),
                        tooltip: t.address_ownership_clear_tooltip,
                        onPressed: _clear,
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.content_paste_rounded,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                      tooltip: t.address_ownership_paste_tooltip,
                      onPressed: _pasteFromClipboard,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 24,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedSwitcher(
                  duration: Motion.of(context, Motion.durationFast),
                  switchInCurve: Motion.curveEnter,
                  switchOutCurve: Motion.curveExit,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, if (current != null) current],
                  ),
                  child: _buildInputHint(
                    t,
                    state.isLoading,
                    detectedChain,
                    invalidFormat,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            KeyedSubtree(
              key: _resultKey,
              child: AnimatedSwitcher(
                duration: Motion.of(context, Motion.durationBase),
                switchInCurve: Motion.curveEnter,
                switchOutCurve: Motion.curveExit,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SizeTransition(
                    sizeFactor: anim,
                    axisAlignment: -1,
                    child: child,
                  ),
                ),
                child: _buildResultArea(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputHint(
    AppLocalizations t,
    bool isLoading,
    AddressChain? detectedChain,
    bool invalidFormat,
  ) {
    final colors = context.colors;
    final hintStyle = context.textTheme.bodySmall?.copyWith(
      color: colors.textSecondary,
    );

    if (isLoading) {
      return Row(
        key: const ValueKey('hint-loading'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Text(t.address_ownership_verifying, style: hintStyle),
        ],
      );
    }

    if (invalidFormat) {
      return Row(
        key: const ValueKey('hint-invalid'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: colors.negativeColor,
          ),
          const SizedBox(width: 6),
          Text(
            t.address_ownership_invalid_format,
            style: hintStyle?.copyWith(color: colors.negativeColor),
          ),
        ],
      );
    }

    if (detectedChain != null) {
      final label = detectedChain == AddressChain.bitcoin
          ? t.address_ownership_chain_bitcoin
          : t.address_ownership_chain_liquid;
      return Row(
        key: ValueKey('hint-chain-$label'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            detectedChain == AddressChain.bitcoin
                ? Icons.currency_bitcoin_rounded
                : Icons.water_drop_rounded,
            size: 16,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(t.address_ownership_detected(label), style: hintStyle),
        ],
      );
    }

    return const SizedBox(key: ValueKey('hint-empty'));
  }

  Widget _buildResultArea(AddressOwnershipState state) {
    if (state.error != null) {
      final colors = context.colors;
      return GlassPanel(
        key: const ValueKey('result-error'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: colors.negativeColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.error!.localize(context),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (state.match != null) {
      return Padding(
        key: ValueKey('result-${state.match!.address}-${state.match!.isOwned}'),
        padding: EdgeInsets.zero,
        child: AddressOwnershipResult(match: state.match!),
      );
    }
    return const SizedBox(key: ValueKey('result-empty'));
  }
}
