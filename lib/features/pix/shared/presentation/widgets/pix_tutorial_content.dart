import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

const Color _kPixTutorialAccent = Color(0xFFE91E63);

Widget pixTutorialContentCard({
  required String title,
  required String body,
  required String buttonLabel,
  required VoidCallback onPressed,
  bool center = false,
}) {
  final card = Container(
    padding: const EdgeInsets.all(20),
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPixTutorialAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  if (!center) return card;

  return Builder(
    builder: (context) {
      final media = MediaQuery.of(context);
      final maxHeight =
          media.size.height - media.padding.top - media.padding.bottom - 32;
      return SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: card,
            ),
          ),
        ),
      );
    },
  );
}

/// Off-screen target position used for "centered" steps that don't highlight
/// any particular widget (mirrors the Merchant Mode welcome/conclusion steps).
TargetPosition pixTutorialCenteredPosition(BuildContext context) {
  final size = MediaQuery.of(context).size;
  return TargetPosition(
    Size(size.width * 0.9, 200),
    Offset(size.width * 1.5, size.height * 0.2),
  );
}

/// Builds a [TutorialCoachMark] with the shared PIX styling.
TutorialCoachMark buildPixCoachMark({
  required List<TargetFocus> targets,
  VoidCallback? onSkip,
  VoidCallback? onFinish,
}) {
  return TutorialCoachMark(
    targets: targets,
    colorShadow: Colors.green,
    paddingFocus: 10,
    opacityShadow: 0.95,
    alignSkip: Alignment.topRight,
    onFinish: () => onFinish?.call(),
    onSkip: () {
      onSkip?.call();
      return true;
    },
  );
}

void showPixCoachMarkWhenReady(
  GlobalKey key,
  VoidCallback show, {
  int retries = 30,
  String? label,
  VoidCallback? onTimeout,
}) {
  Offset? lastOffset;

  void attempt(int remaining) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      final renderObject = context?.findRenderObject();
      final isRendered =
          context != null &&
          renderObject is RenderBox &&
          renderObject.attached &&
          renderObject.hasSize;

      if (isRendered) {
        final routeAnimation = ModalRoute.of(context)?.animation;
        final routeSettled =
            routeAnimation == null || routeAnimation.isCompleted;

        final offset = renderObject.localToGlobal(Offset.zero);
        final offsetStable = lastOffset == offset;
        lastOffset = offset;

        if (routeSettled && offsetStable) {
          show();
          return;
        }
      }

      if (remaining > 0) {
        Future.delayed(
          const Duration(milliseconds: 50),
          () => attempt(remaining - 1),
        );

      } else {
        debugPrint(
          '[PixTutorial] target "${label ?? key.toString()}" never became '
          'ready/stable (context: ${context != null}, '
          'renderBox: ${renderObject is RenderBox}); skipping its coach mark.',
        );
        onTimeout?.call();
      }
    });

    WidgetsBinding.instance.scheduleFrame();
  }

  attempt(retries);
}

class PixTutorialCompletionModal {
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onFinish,
    required VoidCallback onRestart,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final t = AppLocalizations.of(dialogContext);
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 44,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t.pix_tutorial_done_title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.pix_tutorial_done_body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: t.common_finish,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onFinish();
                },
              ),
              const SizedBox(height: 8),
              SecondaryButton(
                text: t.pix_tutorial_restart,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onRestart();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
