import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/action.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/external_navigation.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/toggle.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class LabelSettings extends StatefulWidget {
  final String title;
  final String? iconPathSVG;
  final SettingsActions? action;
  final bool highlight;

  const LabelSettings({
    super.key,
    required this.title,
    this.iconPathSVG,
    this.action,
    this.highlight = false,
  });

  @override
  State<LabelSettings> createState() => _LabelSettingsState();
}

class _LabelSettingsState extends State<LabelSettings> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient:
            widget.highlight
                ? LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [AppColors.primaryColor, AppColors.backgroundCard],
                )
                : null,
        color: widget.highlight ? null : AppColors.backgroundCard,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.action != null ? () => widget.action!.execute() : null,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10, left: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    if (widget.iconPathSVG != null)
                      SvgPicture.asset(
                        widget.iconPathSVG!,
                        width: 20,
                        height: 20,
                      ),
                    if (widget.iconPathSVG != null) const SizedBox(width: 20),
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                if (widget.action is Navigation)
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color:
                          widget.highlight
                              ? AppColors.backgroundColor
                              : AppColors.primaryColor,
                    ),
                  ),
                if (widget.action is ExternalNavigation)
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: SvgPicture.asset(
                      'assets/icons/menu/settings/open_in_new.svg',
                    ),
                  ),
                if (widget.action is Toggle)
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: SizedBox(
                      width: 48,
                      height: 27,
                      child: Switch.adaptive(
                        value: true,
                        onChanged: (value) {},
                        activeColor: Colors.white,
                        activeTrackColor: Colors.green,
                        inactiveThumbColor: const Color(0xFFD9D9D9),
                        inactiveTrackColor: const Color(0xFF545454),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
