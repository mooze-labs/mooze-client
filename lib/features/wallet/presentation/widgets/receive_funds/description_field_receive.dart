import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final receiveDescriptionProvider = StateProvider<String>((ref) => '');

class DescriptionFieldReceive extends ConsumerWidget {
  const DescriptionFieldReceive({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = ref.watch(receiveDescriptionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descrição (opcional)',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: description,
          onChanged: (value) {
            ref.read(receiveDescriptionProvider.notifier).state = value;
          },
          maxLines: 2,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'Ex: Pagamento do almoço',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.all(16),
            counterStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
