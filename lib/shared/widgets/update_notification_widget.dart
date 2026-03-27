import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/providers/update_provider.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UpdateNotificationWidget extends ConsumerStatefulWidget {
  const UpdateNotificationWidget({super.key});

  @override
  ConsumerState<UpdateNotificationWidget> createState() =>
      _UpdateNotificationWidgetState();
}

class _UpdateNotificationWidgetState
    extends ConsumerState<UpdateNotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isVisible = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _showWithAnimation() {
    if (!_isVisible && !_isDismissing) {
      setState(() {
        _isVisible = true;
      });
      _slideController.forward();
      _fadeController.forward();
    }
  }

  Future<void> _dismissWithAnimation() async {
    if (_isVisible && !_isDismissing) {
      setState(() {
        _isDismissing = true;
      });

      await Future.wait([
        _slideController.reverse(),
        _fadeController.reverse(),
      ]);

      if (mounted) {
        ref.read(updateNotifierProvider.notifier).dismissUpdate();
        setState(() {
          _isVisible = false;
          _isDismissing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldShow = ref.watch(shouldShowUpdateNotificationProvider);
    final updateState = ref.watch(updateNotifierProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shouldShow && !_isVisible && !_isDismissing) {
        _showWithAnimation();
      } else if (!shouldShow && _isVisible && !_isDismissing) {
        _dismissWithAnimation();
      }
    });

    if (!shouldShow && !_isVisible) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          decoration: BoxDecoration(
            color: context.colors.backgroundCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.colors.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.primaryColor.withValues(alpha: 0.1),
                offset: Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.system_update_outlined,
                        color: context.colors.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nova atualização disponível',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Versão ${updateState.newVersion}',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismissWithAnimation,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.colors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close,
                          color: context.colors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Atualize para obter melhorias e correções',
                  style: TextStyle(color: context.colors.textTertiary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'ATUALIZAR',
                  height: 44,
                  onPressed: () {
                    _showUpdateDialog(
                      context,
                      updateState.newVersion ?? '',
                      updateState.localVersion ?? '',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdateDialog(
    BuildContext context,
    String newVersion,
    String localVersion,
  ) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: AlertDialog(
              backgroundColor: context.colors.backgroundCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.colors.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.system_update_outlined,
                      color: context.colors.primaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Atualização Disponível',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uma nova versão do aplicativo está disponível.',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Versão atual:',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            localVersion,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nova versão:',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            newVersion,
                            style: TextStyle(
                              color: context.colors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Recomendamos atualizar para obter as melhorias mais recentes e correções de bugs.',
                    style: TextStyle(
                      color: context.colors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        text: 'MAIS TARDE',
                        height: 44,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        text: 'ATUALIZAR',
                        height: 44,
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openUpdateStore();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openUpdateStore() {
    if (Platform.isAndroid) {
      launchUrlString(
        "https://mooze.app",
        mode: LaunchMode.externalApplication,
      );
    } else if (Platform.isIOS) {
      launchUrlString(
        "https://testflight.apple.com/join/BmxNjKb1",
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
