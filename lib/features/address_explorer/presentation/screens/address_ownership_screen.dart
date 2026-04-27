import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/controllers/address_ownership_controller.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/widgets/address_ownership_result.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

class AddressOwnershipScreen extends ConsumerStatefulWidget {
  const AddressOwnershipScreen({super.key});

  @override
  ConsumerState<AddressOwnershipScreen> createState() =>
      _AddressOwnershipScreenState();
}

class _AddressOwnershipScreenState
    extends ConsumerState<AddressOwnershipScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      _controller.text = text;
      _verify();
    }
  }

  void _verify() {
    final text = _controller.text;
    ref.read(addressOwnershipControllerProvider.notifier).verify(text);
  }

  void _clear() {
    _controller.clear();
    ref.read(addressOwnershipControllerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(addressOwnershipControllerProvider);
    final theme = Theme.of(context);
    final hasInput = _controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.address_ownership_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.address_ownership_description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                minLines: 2,
                maxLines: 4,
                onSubmitted: (_) => _verify(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: t.address_ownership_input_hint,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded),
                    tooltip: t.address_ownership_paste_tooltip,
                    onPressed: _pasteFromClipboard,
                  ),
                ),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          (state.isLoading || !hasInput) ? null : _verify,
                      icon: const Icon(Icons.verified_outlined),
                      label: Text(
                        state.isLoading
                            ? t.address_ownership_verifying
                            : t.address_ownership_verify,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: state.isLoading ? null : _clear,
                    child: Text(t.address_ownership_clear),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (state.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (state.error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.error!.localize(context),
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                )
              else if (state.match != null)
                AddressOwnershipResult(match: state.match!),
            ],
          ),
        ),
      ),
    );
  }
}
