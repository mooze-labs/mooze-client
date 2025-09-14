import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final receiveDescriptionProvider = StateProvider<String>((ref) => '');

class DescriptionField extends ConsumerWidget {
  const DescriptionField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Adicione uma descrição para o pagamento...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            helperText: 'Esta descrição aparecerá no QR code/invoice',
          ),
          onChanged: (value) {
            ref.read(receiveDescriptionProvider.notifier).state = value;
          },
        ),
      ],
    );
  }
}
