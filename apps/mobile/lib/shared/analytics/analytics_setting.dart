import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/generated/app_localizations.dart';
import 'providers.dart';

class AnalyticsSetting extends ConsumerWidget {
  const AnalyticsSetting({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);
    if (!analytics.configured) return const SizedBox.shrink();
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(t.analytics_opt_in),
            subtitle: compact ? null : Text(t.analytics_description),
            value: analytics.enabled,
            onChanged: analytics.busy
                ? null
                : (value) async {
                    if (value && compact) {
                      final accepted = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(t.analytics_opt_in),
                          content: Text(t.analytics_description),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(t.common_cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(t.common_confirm),
                            ),
                          ],
                        ),
                      );
                      if (accepted != true) return;
                    }
                    await analytics.setEnabled(value);
                  },
          ),
          if (analytics.error)
            Text(
              t.analytics_save_error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}
