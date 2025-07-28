import 'package:flutter/material.dart';

class TertiaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isEnabled;

  const TertiaryButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
  }) : super(key: key);

  static const Color _backgroundColor = Color(0xFF2B2D33);
  static const Color _textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(
        icon,
        size: 18,
        color: _textColor,
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _textColor,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
