import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/locale_provider.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_divider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

class LanguageSelectorScreen extends ConsumerWidget {
  const LanguageSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final current = ref.watch(localeProvider);

    final options = <_LanguageOption>[
      _LanguageOption(locale: null, label: t.language_system),
      _LanguageOption(
        locale: const Locale('pt'),
        label: t.language_portuguese,
      ),
      _LanguageOption(
        locale: const Locale('en'),
        label: t.language_english,
      ),
      _LanguageOption(
        locale: const Locale('es'),
        label: t.language_spanish,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings_language),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15, left: 20, bottom: 10),
                child: Text(
                  t.settings_section_language,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: List.generate(options.length, (index) {
                    final option = options[index];
                    return Column(
                      children: [
                        _buildOption(
                          context: context,
                          ref: ref,
                          option: option,
                          current: current,
                        ),
                        if (index < options.length - 1) const LabelDivider(),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required WidgetRef ref,
    required _LanguageOption option,
    required Locale? current,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = current?.languageCode == option.locale?.languageCode;

    return Container(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerLow),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              ref.read(localeProvider.notifier).setLocale(option.locale),
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10, left: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  option.label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: colorScheme.primary,
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

class _LanguageOption {
  final Locale? locale;
  final String label;

  const _LanguageOption({required this.locale, required this.label});
}
