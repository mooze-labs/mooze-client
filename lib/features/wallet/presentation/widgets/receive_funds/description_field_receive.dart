import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final receiveDescriptionProvider = StateProvider<String>((ref) => '');

class DescriptionFieldReceive extends ConsumerStatefulWidget {
  const DescriptionFieldReceive({super.key});

  @override
  ConsumerState<DescriptionFieldReceive> createState() =>
      _DescriptionFieldReceiveState();
}

class _DescriptionFieldReceiveState
    extends ConsumerState<DescriptionFieldReceive> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final description = ref.watch(receiveDescriptionProvider);

    if (description.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descrição (opcional)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
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
