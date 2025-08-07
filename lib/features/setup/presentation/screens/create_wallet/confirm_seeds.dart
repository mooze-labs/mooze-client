import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/selected_words_row.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/word_grid_selector.dart';
import 'package:mooze_mobile/shared/key_management/providers.dart';

class ConfirmMnemonicScreen extends ConsumerStatefulWidget {
  const ConfirmMnemonicScreen({super.key});

  @override
  ConsumerState<ConfirmMnemonicScreen> createState() =>
      _ConfirmMnemonicScreenState();
}

class _ConfirmMnemonicScreenState extends ConsumerState<ConfirmMnemonicScreen> {
  late List<int> positions;
  late List<String> words;
  late List<String> shuffledWords;
  final Random random = Random();
  bool _isLoading = true;
  bool _hasValidData = false;

  Map<int, String> selectedWords = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mnemonic = GoRouterState.of(context).extra as String?;

    if (mnemonic == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go("/setup/create-wallet/configure-seeds");
      });
      return;
    }

    words = mnemonic.split(" ");

    positions = [];
    while (positions.length < 3) {
      int pos = random.nextInt(words.length) + 1;
      if (!positions.contains(pos)) {
        positions.add(pos);
      }
    }
    positions.sort();

    _createShuffledWords();

    setState(() {
      _isLoading = false;
      _hasValidData = true;
    });
  }

  void _createShuffledWords() {
    Set<String> wordSet = {};

    for (int pos in positions) {
      wordSet.add(words[pos - 1]);
    }

    while (wordSet.length < 12) {
      String randomWord = words[random.nextInt(words.length)];
      wordSet.add(randomWord);
    }

    shuffledWords = wordSet.toList();
    shuffledWords.shuffle(random);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_hasValidData) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Confirme sua frase",
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () => context.go("/setup/create-wallet/configure-seeds"),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => context.go("/setup/create-wallet/configure-seeds"),
        ),
        title: Text('Confirme sua Frase'),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TitleAndSubtitleCreateWallet(
              title: 'Confirmação de ',
              highlighted: 'Segurança',
              subtitle:
                  'Selecione as palavras na ordem correta para confirmar sua frase de recuperação.',
            ),
            SizedBox(height: 40),

            SelectedWordsRow(
              positions: positions,
              selectedWords: selectedWords,
            ),
            SizedBox(height: 40),

            // Grid de palavras disponíveis
            Expanded(
              child: WordSelectionGrid(
                shuffledWords: shuffledWords,
                selectedWords: selectedWords,
                onWordSelected: _selectWord,
                getWordPosition: _getWordPosition,
              ),
            ),

            SizedBox(height: 10),
            PrimaryButton(
              text: 'Confirmar',
              onPressed: _confirm,
              isEnabled: _canConfirm(),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  int? _getWordPosition(String word) {
    for (var entry in selectedWords.entries) {
      if (entry.value == word) {
        return entry.key;
      }
    }
    return null;
  }

  void _selectWord(String word) {
    setState(() {
      if (selectedWords.containsValue(word)) {
        selectedWords.removeWhere((key, value) => value == word);
        return;
      }

      for (int position in positions) {
        if (!selectedWords.containsKey(position)) {
          selectedWords[position] = word;
          break;
        }
      }
    });
  }

  bool _canConfirm() {
    return selectedWords.length == positions.length;
  }

  bool _checkInputs() {
    for (int position in positions) {
      final selectedWord = selectedWords[position];
      final correctWord = words[position - 1];

      if (selectedWord == null ||
          selectedWord.trim().toLowerCase() != correctWord.toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  void _confirm() async {
    if (_checkInputs()) {
      await ref.read(mnemonicStoreProvider).saveMnemonic(words.join(" ")).run();
      if (mounted) {
        context.go("/setup/pin/new");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Uma ou mais palavras estão incorretas. Tente novamente.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}