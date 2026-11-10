import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets/backdrop_page_scaffold.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/user_id_provider.dart';
import '../widgets/support_error_widget.dart';
import '../widgets/user_id_container_widget.dart';
import '../widgets/user_id_loading_skeleton.dart';

/// Support screen: a glass header that explains the help channel, the
/// support code of the user in a glass panel, and the Telegram contact
/// button pinned above the bottom edge.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen>
    with SingleTickerProviderStateMixin {
  /// Fades and raises the content once, when the screen opens.
  late final AnimationController _animationController = AnimationController(
    duration: Motion.durationBase,
    vsync: this,
  );
  late final Animation<double> _entrance = CurvedAnimation(
    parent: _animationController,
    curve: Motion.curveEnter,
  );
  bool _isRetrying = false;
  String? _lastUserId;
  bool _hasError = false;
  String? _lastErrorTitle;
  String? _lastErrorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationController.isDismissed) {
      if (Motion.isReduced(context)) {
        _animationController.value = 1;
      } else {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _launchTelegramSupport(BuildContext context) async {
    final Uri url = Uri.parse("https://t.me/Moozep2pbot");
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showErrorSnackBar(context);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context);
      }
    }
  }

  void _showErrorSnackBar(BuildContext context) {
    AppSnackBar.error(
      context,
      AppLocalizations.of(context).support_telegram_open_error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);

    return BackdropPageScaffold(
      title: t.support_screen_title,
      actions: [
        OfflineIndicator(onTap: () => OfflinePriceInfoOverlay.show(context)),
      ],
      bottomAction: FadeSlideIn(
        animation: _entrance,
        child: PrimaryButton(
          text: t.support_contact_button,
          onPressed: () => _launchTelegramSupport(context),
        ),
      ),
      body: FadeSlideIn(
        animation: _entrance,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            BackdropPageScaffold.gutter,
            16,
            BackdropPageScaffold.gutter,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SupportHeader(),
              Padding(
                padding: const EdgeInsets.only(top: 24, left: 16, bottom: 8),
                child: Semantics(
                  header: true,
                  child: Text(
                    t.support_user_code_label,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final userIdAsync = ref.watch(userIdControllerProvider);
                  return userIdAsync.when(
                    loading: () {
                      if (_isRetrying && _hasError && _lastErrorTitle != null) {
                        return SupportErrorWidget(
                          title: _lastErrorTitle!,
                          message: _lastErrorMessage ?? '',
                          colorScheme: colorScheme,
                          isLoading: true,
                          onRetry: () {},
                        );
                      }
                      return UserIdLoadingSkeleton(colorScheme: colorScheme);
                    },
                    error: (error, stack) {
                      final errorTitle = t.support_user_code_load_error_title;
                      final errorMessage = t.support_user_code_load_error_msg;

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _hasError = true;
                            _lastErrorTitle = errorTitle;
                            _lastErrorMessage = errorMessage;
                          });
                        }
                      });

                      return SupportErrorWidget(
                        title: errorTitle,
                        message: errorMessage,
                        colorScheme: colorScheme,
                        isLoading: _isRetrying,
                        onRetry: () async {
                          setState(() => _isRetrying = true);
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                          await ref
                              .read(userIdControllerProvider.notifier)
                              .refresh();
                          if (mounted) {
                            setState(() {
                              _isRetrying = false;
                            });
                          }
                        },
                      );
                    },
                    data: (userId) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _hasError) {
                          setState(() {
                            _hasError = false;
                            _lastErrorTitle = null;
                            _lastErrorMessage = null;
                          });
                        }
                      });

                      if (userId == null) {
                        final errorTitle = t.support_user_code_load_error_title;
                        final errorMessage = t.support_user_code_not_found;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _hasError = true;
                              _lastErrorTitle = errorTitle;
                              _lastErrorMessage = errorMessage;
                            });
                          }
                        });

                        return SupportErrorWidget(
                          title: errorTitle,
                          message: errorMessage,
                          colorScheme: colorScheme,
                          isLoading: _isRetrying,
                          onRetry: () async {
                            setState(() => _isRetrying = true);
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                            await ref
                                .read(userIdControllerProvider.notifier)
                                .refresh();
                            if (mounted) {
                              setState(() {
                                _isRetrying = false;
                              });
                            }
                          },
                        );
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _lastUserId != userId) {
                          setState(() => _lastUserId = userId);
                        }
                      });

                      return UserIdContainerWidget(
                        userId: userId,
                        hasError: false,
                        colorScheme: colorScheme,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The help header: a lens icon well, the title, and a muted subtitle,
/// centered in a glass panel.
class _SupportHeader extends StatelessWidget {
  const _SupportHeader();

  static const double _wellSize = 56;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          Container(
            width: _wellSize,
            height: _wellSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GlassStyle.of(context).lensFill,
              border: Border.all(color: AppSurfaces.hairline(context)),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              size: _wellSize / 2,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.support_help_title,
            style: context.textTheme.titleLarge?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            t.support_help_subtitle,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
