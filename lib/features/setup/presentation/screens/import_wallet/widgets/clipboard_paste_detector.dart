import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/seed_phrase_provider.dart';

class ClipboardPasteDetector extends ConsumerStatefulWidget {
  const ClipboardPasteDetector({super.key});

  @override
  ConsumerState<ClipboardPasteDetector> createState() =>
      _ClipboardPasteDetectorState();
}

class _ClipboardPasteDetectorState
    extends ConsumerState<ClipboardPasteDetector> {
  String? _clipboardContent;
  bool _isChecking = false;
  bool _showBanner = true;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();

      if (text != null && text.isNotEmpty) {
        final words = text.split(RegExp(r'\s+'));
        if (words.length == 12 ||
            words.length == 15 ||
            words.length == 18 ||
            words.length == 21 ||
            words.length == 24) {
          setState(() {
            _clipboardContent = text;
          });
        }
      }
    } catch (e) {
    } finally {
      _isChecking = false;
    }
  }

  void _pasteFromClipboard() {
    if (_clipboardContent == null) return;

    final notifier = ref.read(seedPhraseProvider.notifier);
    final success = notifier.importFullPhrase(_clipboardContent!);

    if (success) {
      setState(() {
        _showBanner = false;
      });

    } else {
      if (mounted) {
        final state = ref.read(seedPhraseProvider);
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text(state.errorMessage!)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(seedPhraseProvider);

    if (!_showBanner ||
        _clipboardContent == null ||
        state.confirmedWords.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.content_paste,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frase semente detectada',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Detectamos uma frase na área de transferência',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              ElevatedButton(
                onPressed: _pasteFromClipboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 18),
                    SizedBox(width: 4),
                    Text('Colar'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showBanner = false;
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text('Ignorar', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
