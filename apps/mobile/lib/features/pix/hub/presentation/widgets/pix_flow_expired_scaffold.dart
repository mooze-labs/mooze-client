import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';

/// Shown when a flow screen opens without its draft.
///
/// It happens when the process restarts while the flow is open, so the screen
/// offers a way back to the hub instead of an empty page.
class PixFlowExpiredScaffold extends StatelessWidget {
  final String title;

  const PixFlowExpiredScaffold({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: BackdropAppBar(title: Text(title)),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: PixStatusView(
                          kind: PixStatusKind.info,
                          title: t.pix_hub_flow_expired,
                        ),
                      ),
                    ),
                  ),
                  PrimaryButton(
                    text: t.pix_hub_back_to_hub,
                    onPressed: () => context.go('/pix'),
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
