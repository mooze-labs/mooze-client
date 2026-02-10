import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/first_access/widgets/mock_app_image.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/first_access/widgets/title_and_subtitle.dart';
import 'widgets.dart';

class FirstAccessScreen extends ConsumerWidget {
  const FirstAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: const [
            SizedBox(height: 40),
            Expanded(child: MockAppImage()),
            TitleAndSubtitle(),
            TermsDefinitionWidget(),
            SizedBox(height: 20),
            BeginWidget(),
            ImportWalletWidget(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
