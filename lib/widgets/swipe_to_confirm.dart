import 'package:flutter/material.dart';

class SwipeToConfirm extends StatefulWidget {
  final Function() onConfirm;
  final String text;
  final Color? backgroundColor;
  final Color? progressColor;
  final Color? textColor;
  final double width;

  const SwipeToConfirm({
    Key? key,
    required this.onConfirm,
    required this.text,
    this.backgroundColor,
    this.progressColor,
    this.textColor,
    this.width = 300,
  }) : super(key: key);

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> {
  double _progress = 0.0;
  bool _hasConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (_hasConfirmed) return;

        setState(() {
          _progress += details.delta.dx / 300;
          _progress = _progress.clamp(0.0, 1.0);
        });

        if (_progress >= 0.8 && !_hasConfirmed) {
          setState(() {
            _hasConfirmed = true;
          });
          widget.onConfirm();
        }
      },
      onHorizontalDragEnd: (_) {
        if (_progress < 1.0 || _hasConfirmed) {
          setState(() {
            _progress = 0.0;
            _hasConfirmed = false;
          });
        }
      },
      child: Container(
        width: 300,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.primary),
        ),
        child: Stack(
          children: [
            // Progress indicator
            FractionallySizedBox(
              widthFactor: _progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ),
            // Text
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_forward),
                  const SizedBox(width: 8),
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontFamily: "roboto",
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
