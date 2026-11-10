import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Page shell of the wallet setup screens: the PIN, the biometrics and the
/// length of the recovery phrase.
///
/// It is the page of the main screens: the screen backdrop behind a clear
/// app bar, and the content on a 20 pt gutter. The content fills the screen
/// height, so a layout can push the keypad and the main button to the
/// bottom with a [Spacer]. On a short screen, or with large text, the
/// content scrolls instead of overflowing.
///
/// The content fades and rises in once, when the screen opens, over
/// [Motion.durationBase]. It never blocks a tap. With reduced motion it
/// appears at once.
class PinScreenScaffold extends StatelessWidget {
  const PinScreenScaffold({
    super.key,
    required this.child,
    this.appBarTitle,
    this.onBack,
  });

  /// Content of the page. It gets at least the full height of the page.
  final Widget child;

  /// Name of the step, shown in the app bar.
  final String? appBarTitle;

  /// Back action. Null hides the back button.
  final VoidCallback? onBack;

  /// Side margin of the content.
  static const double gutter = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The app bar is clear and paints its slice of the backdrop, so the
      // bar and the page read as one surface.
      extendBodyBehindAppBar: true,
      appBar: BackdropAppBar(
        title: appBarTitle == null ? null : Text(appBarTitle!),
        automaticallyImplyLeading: false,
        leading: onBack == null
            ? null
            : BackButton(onPressed: onBack),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: _ContentEntrance(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(gutter, 8, gutter, 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 20,
                    ),
                    child: IntrinsicHeight(child: child),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The title and the instruction of a PIN screen.
///
/// The title ends with [highlight] in the brand color, for example
/// "Create your **PIN**". The title is large and bold, so the brand color
/// keeps the contrast of large text in both themes.
class PinHeader extends StatelessWidget {
  const PinHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.highlight,
    this.textAlign = TextAlign.start,
  });

  final String title;

  /// Words after [title] in the brand color.
  final String? highlight;

  final String subtitle;
  final TextAlign textAlign;

  /// Largest text scale of the title.
  static const double _maxTitleScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final titleStyle = context.textTheme.headlineSmall?.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.2,
    );
    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: title),
                if (highlight != null)
                  TextSpan(
                    text: highlight,
                    style: TextStyle(color: context.colorScheme.primary),
                  ),
              ],
            ),
            textAlign: textAlign,
            // A large title grows with the system text size up to 150%.
            // Body text keeps the full scale.
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: _maxTitleScale),
            style: titleStyle,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: textAlign,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// A quiet text action below the main button, such as "No thanks".
///
/// It keeps a 48 pt touch target and the secondary text color, so the
/// brand color stays on the main button.
class PinTextAction extends StatelessWidget {
  const PinTextAction({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        foregroundColor: context.colors.textPrimary,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: context.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Fades and raises the content once, when the screen opens.
class _ContentEntrance extends StatefulWidget {
  const _ContentEntrance({required this.child});

  final Widget child;

  @override
  State<_ContentEntrance> createState() => _ContentEntranceState();
}

class _ContentEntranceState extends State<_ContentEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationBase,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Motion.curveEnter,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      if (Motion.isReduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(animation: _animation, child: widget.child);
  }
}
