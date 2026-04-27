import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_match.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_status.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/controllers/address_list_controller.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/providers/address_explorer_repository_provider.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/widgets/address_tile.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

class AddressExplorerScreen extends ConsumerStatefulWidget {
  const AddressExplorerScreen({super.key});

  @override
  ConsumerState<AddressExplorerScreen> createState() =>
      _AddressExplorerScreenState();
}

class _AddressExplorerScreenState extends ConsumerState<AddressExplorerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _searchController = TextEditingController();
  AddressMatch? _searchResult;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String input) async {
    if (input.trim().isEmpty) {
      setState(() {
        _searchResult = null;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final useCaseEither =
        await ref.read(findAddressUseCaseProvider.future);
    final match = await useCaseEither.match(
      (_) async => null,
      (useCase) async {
        final res = await useCase.call(input).run();
        return res.match((_) => null, (m) => m);
      },
    );
    if (!mounted) return;
    setState(() {
      _searchResult = match;
      _searching = false;
      if (match != null && match.isOwned && match.chain != null) {
        _tabs.animateTo(match.chain == AddressChain.bitcoin ? 0 : 1);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchResult = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.address_explorer_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _runSearch,
                  decoration: InputDecoration(
                    hintText: t.address_explorer_search_hint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _buildSearchSuffix(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: t.address_explorer_tab_onchain),
                  Tab(text: t.address_explorer_tab_liquid),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_searchResult != null) _SearchBanner(match: _searchResult!),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _AddressList(
                  chain: AddressChain.bitcoin,
                  highlightAddress: _matchedAddressFor(AddressChain.bitcoin),
                ),
                _AddressList(
                  chain: AddressChain.liquid,
                  highlightAddress: _matchedAddressFor(AddressChain.liquid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildSearchSuffix() {
    if (_searching) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_searchController.text.isEmpty) return null;
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: _clearSearch,
    );
  }

  String? _matchedAddressFor(AddressChain chain) {
    final r = _searchResult;
    if (r == null || !r.isOwned || r.chain != chain) return null;
    return r.address;
  }
}

class _SearchBanner extends ConsumerWidget {
  final AddressMatch match;
  const _SearchBanner({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ok = match.isOwned;

    String description;
    if (!ok) {
      description = t.address_explorer_search_no_match;
    } else if (match.derivationIndex != null) {
      final chain = match.chain == AddressChain.bitcoin
          ? t.address_explorer_tab_onchain
          : t.address_explorer_tab_liquid;
      description = t.address_explorer_search_match_at_index(
        chain,
        match.derivationIndex!,
      );
    } else {
      description = match.chain == AddressChain.bitcoin
          ? t.address_explorer_search_match_onchain
          : t.address_explorer_search_match_liquid;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ok ? scheme.primaryContainer : scheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.verified_rounded : Icons.cancel_outlined,
            color: ok ? scheme.onPrimaryContainer : scheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: ok
                    ? scheme.onPrimaryContainer
                    : scheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressList extends ConsumerWidget {
  final AddressChain chain;
  final String? highlightAddress;

  const _AddressList({required this.chain, this.highlightAddress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final asyncList = ref.watch(addressListProvider(chain));
    final currentLimit = ref.watch(addressScanLimitProvider(chain));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(addressListProvider(chain));
        await ref.read(addressListProvider(chain).future);
      },
      child: asyncList.when(
        skipLoadingOnReload: true,
        loading: () => _buildLoading(t),
        error: (err, _) => _buildError(t, err),
        data: (addresses) => _buildList(
          context,
          ref,
          t,
          addresses,
          isLoadingMore: asyncList.isLoading,
          currentLimit: currentLimit,
        ),
      ),
    );
  }

  Widget _buildLoading(AppLocalizations t) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 12),
        Center(
          child: Text(
            t.address_explorer_loading,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildError(AppLocalizations t, Object err) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              t.address_explorer_load_error(err.toString()),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations t,
    List<WalletAddress> addresses, {
    required bool isLoadingMore,
    required int currentLimit,
  }) {
    if (addresses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(child: Text(t.address_explorer_empty)),
        ],
      );
    }

    final usedCount = addresses
        .where((a) => a.status == AddressStatus.used)
        .length;
    final utxoCount =
        addresses.fold<int>(0, (sum, a) => sum + a.utxos.length);
    // Only offer "load more" when the most recent scan returned a full
    // window — otherwise BDK / LWK exhausted the descriptor.
    final canLoadMore = addresses.length >= currentLimit;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: addresses.length + 2, // header + items + footer
      itemBuilder: (context, i) {
        if (i == 0) {
          return _SummaryHeader(
            text: t.address_explorer_summary(
              addresses.length,
              usedCount,
              utxoCount,
            ),
          );
        }
        final lastIndex = addresses.length + 1;
        if (i == lastIndex) {
          return _LoadMoreFooter(
            onTap: canLoadMore
                ? () {
                    ref
                        .read(addressScanLimitProvider(chain).notifier)
                        .state += kAddressLoadMoreSize;
                  }
                : null,
            isLoading: isLoadingMore,
            label: t.address_explorer_load_more(kAddressLoadMoreSize),
            loadingLabel: t.address_explorer_loading_more,
          );
        }
        final addr = addresses[i - 1];
        return AddressTile(
          address: addr,
          highlight: highlightAddress != null &&
              addr.address == highlightAddress,
        );
      },
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final String text;
  const _SummaryHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;
  final String loadingLabel;

  const _LoadMoreFooter({
    required this.onTap,
    required this.isLoading,
    required this.label,
    required this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.keyboard_arrow_down_rounded),
          label: Text(isLoading ? loadingLabel : label),
          onPressed: (onTap == null || isLoading) ? null : onTap,
        ),
      ),
    );
  }
}
