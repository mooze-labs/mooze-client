import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/address_match.dart';
import 'package:mooze_mobile/features/address_explorer/domain/entities/wallet_address.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_status.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/controllers/address_list_controller.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/providers/address_explorer_repository_provider.dart';
import 'package:mooze_mobile/features/address_explorer/presentation/widgets/address_tile.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/backdrop_page_scaffold.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

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
    final useCaseEither = await ref.read(findAddressUseCaseProvider.future);
    final match = await useCaseEither.match((_) async => null, (useCase) async {
      final res = await useCase.call(input).run();
      return res.match((_) => null, (m) => m);
    });
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
    final result = _searchResult;

    return BackdropPageScaffold(
      title: t.address_explorer_title,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BackdropPageScaffold.gutter,
              8,
              BackdropPageScaffold.gutter,
              0,
            ),
            child: GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SearchField(
                    controller: _searchController,
                    hint: t.address_explorer_search_hint,
                    onSubmitted: _runSearch,
                    suffix: _buildSearchSuffix(),
                  ),
                  AnimatedSize(
                    duration: Motion.of(context, Motion.durationBase),
                    curve: Motion.curveMove,
                    alignment: Alignment.topCenter,
                    child: result == null
                        ? const SizedBox(width: double.infinity)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const PanelDivider(indent: 16),
                              _SearchBanner(match: result),
                            ],
                          ),
                  ),
                  const PanelDivider(indent: 16),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: _ChainSelector(
                      controller: _tabs,
                      labels: [
                        t.address_explorer_tab_onchain,
                        t.address_explorer_tab_liquid,
                      ],
                      icons: const [
                        Icons.currency_bitcoin_rounded,
                        Icons.water_drop_rounded,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    final colors = context.colors;
    if (_searching) {
      return Padding(
        padding: const EdgeInsets.all(15),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primaryColor,
          ),
        ),
      );
    }
    if (_searchController.text.isEmpty) return null;
    return IconButton(
      icon: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary),
      onPressed: _clearSearch,
    );
  }

  String? _matchedAddressFor(AddressChain chain) {
    final r = _searchResult;
    if (r == null || !r.isOwned || r.chain != chain) return null;
    return r.address;
  }
}

/// Search row of the control panel: a borderless field on the glass.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;
  final Widget? suffix;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tt = context.textTheme;

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      cursorColor: colors.primaryColor,
      style: tt.bodyMedium?.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: tt.bodyMedium?.copyWith(color: colors.textSecondary),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: colors.textSecondary,
        ),
        suffixIcon: suffix,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        constraints: const BoxConstraints(minHeight: 48),
      ),
    );
  }
}

/// Segmented choice of the chain, bound to the tab controller. A glass lens
/// follows the page swipe under the selected segment.
class _ChainSelector extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  final List<IconData> icons;

  const _ChainSelector({
    required this.controller,
    required this.labels,
    required this.icons,
  });

  static const double _height = 48;
  static const double _inset = 2;

  @override
  Widget build(BuildContext context) {
    final count = labels.length;
    final animation = controller.animation ?? controller;

    return SizedBox(
      height: _height,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final position =
              controller.animation?.value ?? controller.index.toDouble();
          final selected = position.round();
          return Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment(-1 + 2 * position / (count - 1), 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / count,
                    heightFactor: 1,
                    child: const Padding(
                      padding: EdgeInsets.all(_inset),
                      child: GlassLens(),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: _ChainSegment(
                        label: labels[i],
                        icon: icons[i],
                        selected: i == selected,
                        onTap: () => controller.animateTo(i),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChainSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChainSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.textPrimary : colors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
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

/// Result of an address search, shown as a row of the control panel. The
/// status shows only as the small icon.
class _SearchBanner extends ConsumerWidget {
  final AddressMatch match;
  const _SearchBanner({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Icon(
            ok ? Icons.verified_rounded : Icons.cancel_outlined,
            size: 18,
            color: ok ? colors.positiveColor : colors.negativeColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
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

  static const double _gutter = BackdropPageScaffold.gutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final asyncList = ref.watch(addressListProvider(chain));
    final currentLimit = ref.watch(addressScanLimitProvider(chain));
    final filter = ref.watch(addressFilterProvider(chain));

    return RefreshIndicator(
      color: context.colors.primaryColor,
      onRefresh: () async {
        ref.invalidate(addressListProvider(chain));
        await ref.read(addressListProvider(chain).future);
      },
      child: asyncList.when(
        skipLoadingOnReload: true,
        loading: () => _buildLoading(context, t),
        error: (err, _) => _buildError(context, t, err),
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

  Widget _buildLoading(BuildContext context, AppLocalizations t) {
    final colors = context.colors;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            t.address_explorer_loading,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, AppLocalizations t, Object err) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 22,
                color: context.colors.negativeColor,
              ),
              const SizedBox(height: 10),
              Text(
                t.address_explorer_load_error(err.toString()),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
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
    final colors = context.colors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (addresses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(
            child: Text(
              t.address_explorer_empty,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      );
    }

    final usedCount = addresses
        .where((a) => a.status == AddressStatus.used)
        .length;
    final unusedCount = addresses.length - usedCount;
    final utxoCount = addresses.fold<int>(0, (sum, a) => sum + a.utxos.length);
    final canLoadMore = addresses.length >= currentLimit;
    final filtered = _applyFilter(addresses, filter);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 16, bottom: 24 + bottomInset),
      children: [
        _SummaryHeader(
          total: addresses.length,
          used: usedCount,
          unused: unusedCount,
          utxos: utxoCount,
        ),
        _FilterChipsRow(chain: chain, filter: filter),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(_gutter, 24, _gutter, 24),
            child: Text(
              t.address_explorer_filter_empty,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gutter),
            child: GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < filtered.length; i++) ...[
                    if (i > 0) const PanelDivider(indent: 36),
                    AddressTile(
                      address: filtered[i],
                      highlight:
                          highlightAddress != null &&
                          filtered[i].address == highlightAddress,
                    ),
                  ],
                ],
              ),
            ),
          ),
          _LoadMoreFooter(
            onTap: canLoadMore
                ? () {
                    ref.read(addressScanLimitProvider(chain).notifier).state +=
                        kAddressLoadMoreSize;
                  }
                : null,
            isLoading: isLoadingMore,
            label: t.address_explorer_load_more(kAddressLoadMoreSize),
            loadingLabel: t.address_explorer_loading_more,
          ),
        ],
      ],
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
    final colors = context.colors;
    final tt = context.textTheme;
    final t = AppLocalizations.of(context);
    const tabular = [FontFeature.tabularFigures()];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BackdropPageScaffold.gutter + 4,
        0,
        BackdropPageScaffold.gutter,
        4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.address_explorer_summary_addresses(total),
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFeatures: tabular,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            t.address_explorer_summary_status(used, unused),
            style: tt.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontFeatures: tabular,
            ),
          ),
          Text(
            t.address_explorer_summary_utxos_total(utxos),
            style: tt.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontFeatures: tabular,
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
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: BackdropPageScaffold.gutter,
        ),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final (value, label) = entries[i];
          return _FilterChip(
            label: label,
            selected: value == filter,
            onTap: () {
              ref.read(addressFilterProvider(chain).notifier).state = value;
            },
          );
        },
      ),
    );
  }
}

/// Filter pill. The selected pill is raised glass; the others are a
/// hairline outline.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const _radius = BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duration = Motion.of(context, Motion.durationFast);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: _radius,
                    border: Border.all(color: AppSurfaces.hairline(context)),
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: duration,
                  curve: Motion.curveMove,
                  child: const LiquidGlass(
                    blurBackdrop: false,
                    child: SizedBox.expand(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  label,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: selected ? colors.textPrimary : colors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary action under the list: a glass pill that loads more addresses.
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
    final colors = context.colors;
    final enabled = onTap != null && !isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BackdropPageScaffold.gutter,
        16,
        BackdropPageScaffold.gutter,
        0,
      ),
      child: AnimatedOpacity(
        opacity: enabled || isLoading ? 1 : 0.45,
        duration: Motion.of(context, Motion.durationFast),
        curve: Motion.curveMove,
        child: SizedBox(
          height: 48,
          child: LiquidGlass(
            blurBackdrop: false,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: enabled ? onTap : null,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.textSecondary,
                          ),
                        )
                      else
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: colors.textPrimary,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        isLoading ? loadingLabel : label,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
