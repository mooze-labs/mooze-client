import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/first_access/widgets/mock_app_image.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/first_access/widgets/title_and_subtitle.dart';
import 'package:mooze_mobile/shared/analytics/analytics_setting.dart';
import 'package:mooze_mobile/shared/analytics/providers.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/motion/staggered_entrance.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';

import 'widgets.dart';

/// The first screen of a new install: create a wallet or import one.
///
/// The app image fills the space above the content, on the screen backdrop.
/// The title, the consent panel and the actions keep their height and
/// enter in a short stagger. With large text they scroll, and the image
/// gives up its space.
class FirstAccessScreen extends StatelessWidget {
  const FirstAccessScreen({super.key});

  /// Side margin of the content.
  static const double gutter = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 8),
                      child: MockAppImage(),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight,
                    ),
                    child: const SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 12),
                      child: StaggeredEntrance(
                        sessionKey: FirstAccessScreen,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        sections: [
                          TitleAndSubtitle(),
                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: _ConsentPanel(),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [BeginWidget(), ImportWalletWidget()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The terms and, when analytics is available, the analytics choice, in
/// one glass panel split by a hairline.
class _ConsentPanel extends ConsumerWidget {
  const _ConsentPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAnalytics = ref.watch(
      analyticsProvider.select((analytics) => analytics.configured),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TermsDefinitionWidget(),
        if (hasAnalytics) ...[
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: AppSurfaces.hairline(context),
          ),
          const AnalyticsSetting(
            compact: true,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        ],
      ],
    );
  }
}
