import 'package:flutter/material.dart';

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
        final size = MediaQuery.of(context).size;
        return Container(
          width: size.width,
          height: size.height,
          color: Colors.transparent,
          child: Stack(
            children: [
              _buildExpandingCircle(size),
              if (showLoadingText)
                _buildLoadingText(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandingCircle(Size size) {
    return Positioned(
      left: -size.width * 0.8,
      bottom: -size.height * 0.3,
      child: Container(
        width: size.width * circleAnimation.value,
        height: size.width * circleAnimation.value,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildLoadingText() {
    return Center(
      child: Opacity(
        opacity: circleAnimation.value.clamp(0.0, 1.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.black54,
              strokeWidth: 2,
            ),
            SizedBox(height: 24),
            Text(
              'Gerando QR Code...',
              style: TextStyle(
                color: Colors.black87,
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
