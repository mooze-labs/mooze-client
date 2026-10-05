import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/generate_seeds_button.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/phrase_length_selection.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/platform_safe_area.dart';

class ConfigureSeedsScreen extends StatelessWidget {
  const ConfigureSeedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PlatformSafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(t.setup_create_wallet_appbar),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TitleAndSubtitleCreateWallet(
                          title: t.setup_seed_length_title,
                          highlighted: t.setup_seed_length_highlight,
                          subtitle: t.setup_seed_length_subtitle,
                        ),

                        SizedBox(height: 32),

                        SeedPhraseSelector(),

                        Spacer(),

                        GenerateSeedsButton(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
