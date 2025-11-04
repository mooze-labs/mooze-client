import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class LoadingOverlayWidget extends StatelessWidget {
  final AnimationController circleController;
  final Animation<double> circleAnimation;
  final bool showLoadingText;

  const LoadingOverlayWidget({
    Key? key,
    required this.circleController,
    required this.circleAnimation,
    required this.showLoadingText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: circleController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: false,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  _buildExpandingCircle(context),
                  if (showLoadingText) _buildLoadingText(),
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
      left: -size.width * 0.8,
      bottom: -size.height * 0.3,
      child: Container(
        width: size.width * circleAnimation.value * 1.2,
        height: size.width * circleAnimation.value * 1.2,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildLoadingText() {
    return Center(
      child: Opacity(
        opacity: circleAnimation.value.clamp(1.0, 1.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            SizedBox(height: 24),
            Text(
              'Gerando QR Code...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
