import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/api_down_indicator.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class ApiUnavailableOverlay extends ConsumerStatefulWidget {

  final VoidCallback? onRetry;
  final String? customMessage;
  final bool showBackButton;
  final VoidCallback? onBack;

  const ApiUnavailableOverlay({
    super.key,
    this.onRetry,
    this.customMessage,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  ConsumerState<ApiUnavailableOverlay> createState() =>
      _ApiUnavailableOverlayState();
}

class _ApiUnavailableOverlayState extends ConsumerState<ApiUnavailableOverlay>
    with SingleTickerProviderStateMixin {
  bool _isRetrying = false;
  String? _retryError;

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _retryError = null;
    });

    try {
      ref.invalidate(ensureAuthSessionProvider);
      final success = await ref.read(ensureAuthSessionProvider.future);
      if (!mounted) return;

      if (success) {
        widget.onRetry?.call();
      } else {
        final t = AppLocalizations.of(context);
        setState(() => _retryError = t.api_down_dialog_body);
      }
    } catch (_) {
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      setState(() => _retryError = t.api_down_dialog_body);
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApiDown = ref.watch(apiDownProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
      child:
          !isApiDown
              ? const SizedBox.shrink(key: ValueKey('api-up'))
              : _Modal(
                key: const ValueKey('api-down'),
                pulse: _pulse,
                isRetrying: _isRetrying,
                retryError: _retryError,
                customMessage: widget.customMessage,
                showBackButton: widget.showBackButton,
                onBack: widget.onBack,
                onRetry: _handleRetry,
              ),
    );
  }
}

class _Modal extends ConsumerWidget {
  final Animation<double> pulse;
  final bool isRetrying;
  final String? retryError;
  final String? customMessage;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Future<void> Function() onRetry;

  const _Modal({
    super.key,
    required this.pulse,
    required this.isRetrying,
    required this.retryError,
    required this.customMessage,
    required this.showBackButton,
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final warning = context.appColors.warning;
    final statusCode = ref.watch(apiStatusCodeProvider);


    return ColoredBox(
      color: Colors.black.withValues(alpha: isDark ? 0.62 : 0.35),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _SoftCard(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulsingIcon(pulse: pulse, color: warning),
                  const SizedBox(height: 20),
                  Text(
                    t.api_down_dialog_title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    customMessage ?? t.api_down_dialog_body,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  if (statusCode != null) ...[
                    const SizedBox(height: 10),
                    _StatusChip(code: statusCode),
                  ],
                  const SizedBox(height: 20),
                  _WarningPanel(
                    warning: warning,
                    title: t.api_down_maintenance_title,
                    bullets: t.api_down_warning_list,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.api_down_dialog_footer,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.colors.textTertiary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: t.common_retry,
                    isEnabled: !isRetrying,
                    isLoading: isRetrying,
                    onPressed: isRetrying ? null : () => onRetry(),
                  ),
                  _InlineRetryError(message: retryError),
                  if (showBackButton) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed:
                          isRetrying
                              ? null
                              : (onBack ?? () => Navigator.of(context).pop()),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onSurface.withValues(alpha: 0.7),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        t.common_back,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatelessWidget {
  final Animation<double> pulse;
  final Color color;

  const _PulsingIcon({required this.pulse, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = pulse.value;
        return Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.10 + 0.06 * t),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16 + 0.10 * t),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.cloud_off_rounded, size: 26, color: color),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final int code;
  const _StatusChip({required this.code});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'HTTP $code',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _WarningPanel extends StatelessWidget {
  final Color warning;
  final String title;
  final String bullets;

  const _WarningPanel({
    required this.warning,
    required this.title,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: warning, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              bullets,
              style: theme.textTheme.bodySmall?.copyWith(
                color: warning.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineRetryError extends StatelessWidget {
  final String? message;
  const _InlineRetryError({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child:
          (message == null || message!.isEmpty)
              ? const SizedBox.shrink()
              : Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 14,
                      color: cs.error,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        message!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.error,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : cs.surface,
        borderRadius: BorderRadius.circular(24),
        border:
            isDark
                ? Border.all(color: cs.onSurface.withValues(alpha: 0.06))
                : null,
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: child,
    );
  }
}
