import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/selected_words_row.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/title_and_subtitle_create_wallet.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/create_wallet/widgets/word_grid_selector.dart';
import 'package:mooze_mobile/features/wallet/data/storage/balance_snapshot_storage.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_id_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/key_management/providers.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

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
    final t = AppLocalizations.of(context);
    if (_isLoading || !_hasValidData) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.setup_confirm_seed_appbar),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(t.setup_confirm_seed_appbar),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TitleAndSubtitleCreateWallet(
              title: t.setup_confirm_seed_title,
              highlighted: t.setup_confirm_seed_highlight,
              subtitle: t.setup_confirm_seed_subtitle,
            ),
            SizedBox(height: 40),

            SelectedWordsRow(
              positions: positions,
              selectedWords: selectedWords,
            ),
            SizedBox(height: 40),

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
              text: t.common_confirm,
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

      // A brand-new wallet must start from an empty balance state. Wipe any
      // persisted snapshot (defence-in-depth — the create flow is reachable
      // after a delete) and force the walletId to regenerate so the cache-
      // first balance provider re-binds to a fresh, empty namespace.
      await SharedPreferencesBalanceSnapshotStore().clearAll();
      ref.invalidate(mnemonicProvider);
      ref.invalidate(walletIdProvider);
      ref.invalidate(allBalancesProvider);

      if (mounted) {
        selectedWords.clear();
        context.push("/setup/pin/new");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).setup_confirm_seed_error,
            style: const TextStyle(color: Colors.white),
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
