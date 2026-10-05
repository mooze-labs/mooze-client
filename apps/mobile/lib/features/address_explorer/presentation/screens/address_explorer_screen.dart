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
                    prefixIcon: const Icon(Icons.search_rounded),
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
                  Tab(
                    icon: null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.currency_bitcoin_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(t.address_explorer_tab_onchain),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.water_drop_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(t.address_explorer_tab_liquid),
                      ],
                    ),
                  ),
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
      icon: const Icon(Icons.close_rounded),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ok
            ? scheme.primaryContainer.withValues(alpha: 0.6)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(
          color: ok
              ? scheme.primary.withValues(alpha: 0.4)
              : scheme.outlineVariant.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.verified_rounded : Icons.cancel_outlined,
            size: 18,
            color: ok
                ? scheme.primary
                : scheme.error.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: scheme.onSurface,
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
    final filter = ref.watch(addressFilterProvider(chain));

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
          filter: filter,
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
    required AddressListFilter filter,
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
    final unusedCount = addresses.length - usedCount;
    final utxoCount =
        addresses.fold<int>(0, (sum, a) => sum + a.utxos.length);
    final canLoadMore = addresses.length >= currentLimit;
    final filtered = _applyFilter(addresses, filter);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: filtered.length + 3, // header + filter chips + items + footer
      itemBuilder: (context, i) {
        if (i == 0) {
          return _SummaryHeader(
            total: addresses.length,
            used: usedCount,
            unused: unusedCount,
            utxos: utxoCount,
          );
        }
        if (i == 1) {
          return _FilterChipsRow(chain: chain, filter: filter);
        }
        final lastIndex = filtered.length + 2;
        if (i == lastIndex) {
          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Text(
                t.address_explorer_filter_empty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            );
          }
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
        final addr = filtered[i - 2];
        return AddressTile(
          address: addr,
          highlight: highlightAddress != null &&
              addr.address == highlightAddress,
        );
      },
    );
  }

  static List<WalletAddress> _applyFilter(
    List<WalletAddress> all,
    AddressListFilter filter,
  ) {
    switch (filter) {
      case AddressListFilter.all:
        return all;
      case AddressListFilter.used:
        return all.where((a) => a.status == AddressStatus.used).toList();
      case AddressListFilter.unused:
        return all.where((a) => a.status == AddressStatus.unused).toList();
      case AddressListFilter.withUtxos:
        return all.where((a) => a.utxos.isNotEmpty).toList();
    }
  }
}

class _SummaryHeader extends StatelessWidget {
  final int total;
  final int used;
  final int unused;
  final int utxos;

  const _SummaryHeader({
    required this.total,
    required this.used,
    required this.unused,
    required this.utxos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.address_explorer_summary_addresses(total),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            t.address_explorer_summary_status(used, unused),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            t.address_explorer_summary_utxos_total(utxos),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipsRow extends ConsumerWidget {
  final AddressChain chain;
  final AddressListFilter filter;

  const _FilterChipsRow({required this.chain, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final entries = <(AddressListFilter, String)>[
      (AddressListFilter.all, t.address_explorer_filter_all),
      (AddressListFilter.used, t.address_explorer_filter_used),
      (AddressListFilter.unused, t.address_explorer_filter_unused),
      (AddressListFilter.withUtxos, t.address_explorer_filter_with_utxos),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final (value, label) = entries[i];
          final selected = value == filter;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            visualDensity: VisualDensity.compact,
            onSelected: (_) {
              ref.read(addressFilterProvider(chain).notifier).state = value;
            },
          );
        },
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
