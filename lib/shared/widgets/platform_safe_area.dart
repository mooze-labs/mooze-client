import 'dart:io';
import 'package:flutter/material.dart';

class PlatformSafeArea extends StatelessWidget {
  final Widget child;

  final bool iosTop;
  final bool iosBottom;
  final bool iosLeft;
  final bool iosRight;

  final bool androidTop;
  final bool androidBottom;
  final bool androidLeft;
  final bool androidRight;

  final EdgeInsets minimum;

  const PlatformSafeArea({
    super.key,
    required this.child,
    this.iosTop = false,
    this.iosBottom = false,
    this.iosLeft = false,
    this.iosRight = false,
    this.androidTop = true,
    this.androidBottom = true,
    this.androidLeft = true,
    this.androidRight = true,
    this.minimum = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return SafeArea(
      top: isIOS ? iosTop : androidTop,
      bottom: isIOS ? iosBottom : androidBottom,
      left: isIOS ? iosLeft : androidLeft,
      right: isIOS ? iosRight : androidRight,
      minimum: minimum,
      child: child,
    );
  }
}
