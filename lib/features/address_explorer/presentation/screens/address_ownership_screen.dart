import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/domain/services/address_chain_detector.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/controllers/address_ownership_controller.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/widgets/address_ownership_result.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

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

  Color _inputBorderColor(ColorScheme scheme) =>
      scheme.brightness == Brightness.light
          ? scheme.outline
          : scheme.outlineVariant.withValues(alpha: 0.6);

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
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.removeCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _scrollToResult() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(addressOwnershipControllerProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = _inputBorderColor(scheme);

    final raw = _controller.text.trim();
    final hasInput = raw.isNotEmpty;
    final cleaned = _detector.stripUriScheme(raw);
    final detectedChain = _detectedChain(raw);
    final invalidFormat = hasInput &&
        cleaned.length >= _kMinAddressLength &&
        _detector.detect(cleaned).isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.address_ownership_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.address_ownership_description,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.address_ownership_subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
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
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: t.address_ownership_input_hint,
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: scheme.primary.withValues(alpha: 0.6),
                      width: 1.4,
                    ),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(14, 14, 96, 14),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasInput)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          tooltip: t.address_ownership_clear_tooltip,
                          onPressed: _clear,
                        ),
                      IconButton(
                        icon: const Icon(Icons.content_paste_rounded, size: 20),
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildInputHint(
                    t,
                    theme,
                    state.isLoading,
                    detectedChain,
                    invalidFormat,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              KeyedSubtree(
                key: _resultKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SizeTransition(
                      sizeFactor: anim,
                      axisAlignment: -1,
                      child: child,
                    ),
                  ),
                  child: _buildResultArea(state, theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputHint(
    AppLocalizations t,
    ThemeData theme,
    bool isLoading,
    AddressChain? detectedChain,
    bool invalidFormat,
  ) {
    final scheme = theme.colorScheme;

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
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            t.address_ownership_verifying,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    if (invalidFormat) {
      return Row(
        key: const ValueKey('hint-invalid'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 16, color: scheme.error.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          Text(
            t.address_ownership_invalid_format,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.error.withValues(alpha: 0.85),
            ),
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
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            t.address_ownership_detected(label),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return const SizedBox(key: ValueKey('hint-empty'));
  }

  Widget _buildResultArea(AddressOwnershipState state, ThemeData theme) {
    if (state.error != null) {
      final scheme = theme.colorScheme;
      return Container(
        key: const ValueKey('result-error'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          border: Border.all(color: _inputBorderColor(scheme)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                size: 20, color: scheme.error.withValues(alpha: 0.85)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.error!.localize(context),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
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
