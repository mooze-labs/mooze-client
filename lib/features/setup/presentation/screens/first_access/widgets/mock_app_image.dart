import 'package:flutter/material.dart';

class MockAppImage extends StatelessWidget {
  const MockAppImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Center(
        child: Image.asset(
          'assets/images/getstarted/getstarted_mock.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
