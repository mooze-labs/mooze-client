import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/theme_mode_provider.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_divider.dart';

class ThemeSelectorScreen extends ConsumerWidget {
  const ThemeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);

    final options = [
      _ThemeOption(
        mode: ThemeMode.system,
        label: 'Sistema',
        icon: Icons.brightness_auto_rounded,
      ),
      _ThemeOption(
        mode: ThemeMode.light,
        label: 'Claro',
        icon: Icons.light_mode_rounded,
      ),
      _ThemeOption(
        mode: ThemeMode.dark,
        label: 'Escuro',
        icon: Icons.dark_mode_rounded,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tema'),
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
                  'APARÊNCIA',
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
                          currentMode: currentMode,
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
    required _ThemeOption option,
    required ThemeMode currentMode,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = currentMode == option.mode;

    return Container(
      decoration: BoxDecoration(
        // gradient: isSelected
        //     ? LinearGradient(
        //         begin: Alignment.centerRight,
        //         end: Alignment.centerLeft,
        //         colors: [
        //           colorScheme.primary,
        //           colorScheme.surfaceContainerLowest,
        //         ],
        //       )
        //     : null,
        color: colorScheme.surfaceContainerLow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              () => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(option.mode),
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10, left: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      option.icon,
                      size: 20,
                      color:
                          isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                    ),
                    const SizedBox(width: 20),
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color:
                        isSelected ? colorScheme.primary : colorScheme.primary,
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

class _ThemeOption {
  final ThemeMode mode;
  final String label;
  final IconData icon;

  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.icon,
  });
}
