import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_funds/description_field_receive.dart'
    show receiveUnderlineDecoration;
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

final receiveDescriptionProvider = StateProvider<String>((ref) => '');

/// Always-open description field with the receive underline style.
///
/// The receive screen uses `DescriptionFieldReceive`. This field keeps its
/// own provider.
class DescriptionField extends ConsumerWidget {
  const DescriptionField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.receive_description_label,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          maxLines: 3,
          maxLength: 200,
          cursorColor: context.colors.primaryColor,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.textPrimary,
          ),
          decoration: receiveUnderlineDecoration(
            context,
            hintText: t.receive_description_hint,
          ),
          onChanged: (value) {
            ref.read(receiveDescriptionProvider.notifier).state = value;
          },
        ),
      ],
    );
  }
}
