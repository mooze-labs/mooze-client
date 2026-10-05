import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Full-screen blocking overlay used while a PIX charge or payment is being
/// created.
///
/// Shows the step label as soon as the reveal animation covers the screen.
/// After [slowAfter] it adds a second line so a stalled request does not
/// look frozen; the caller still owns dismissal and retry.
class LoadingOverlayWidget extends StatefulWidget {
  final AnimationController circleController;
  final Animation<double> circleAnimation;
  final bool showLoadingText;
  final String loadingText;
  final Duration slowAfter;

  const LoadingOverlayWidget({
    super.key,
    required this.circleController,
    required this.circleAnimation,
    required this.showLoadingText,
    required this.loadingText,
    this.slowAfter = const Duration(seconds: 15),
  });

  @override
  State<LoadingOverlayWidget> createState() => _LoadingOverlayWidgetState();
}

class _LoadingOverlayWidgetState extends State<LoadingOverlayWidget> {
  Timer? _slowTimer;
  bool _isSlow = false;

  @override
  void initState() {
    super.initState();
    _slowTimer = Timer(widget.slowAfter, () {
      if (mounted) setState(() => _isSlow = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.circleController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: false,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  _buildExpandingCircle(context),
                  if (widget.showLoadingText &&
                      widget.circleAnimation.value >= 2)
                    _buildLoadingText(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandingCircle(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: -size.width * 1.2,
      bottom: -size.height * 0.3,
      child: Container(
        width: size.width * widget.circleAnimation.value * 1.2,
        height: size.width * widget.circleAnimation.value * 1.5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildLoadingText(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            const SizedBox(height: 24),
            Text(
              widget.loadingText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
                letterSpacing: 0.5,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child:
                  _isSlow
                      ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          t.common_taking_longer,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
