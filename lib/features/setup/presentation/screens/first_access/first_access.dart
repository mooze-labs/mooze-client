import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets.dart';

const String logoPath = 'assets/images/mooze-logo.png';

class FirstAccessScreen extends ConsumerWidget {
  const FirstAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Image.asset(logoPath, width: 200, height: 200),
            SizedBox(height: 50),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                children: [
                  TermsDefinitionWidget(),
                  SizedBox(height: 20),
                  BeginWidget(),
                  SizedBox(height: 20),
                  ImportWalletWidget(),
                ],
              ),
            ),
            Spacer(),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
