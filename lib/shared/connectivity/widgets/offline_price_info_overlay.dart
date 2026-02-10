import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/cache_info_provider.dart';
import '../providers/connectivity_provider.dart';

class OfflinePriceInfoOverlay {
  static void show(BuildContext context) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => overlayEntry.remove(),
                  child: Container(color: Colors.black.withValues(alpha: 0.3)),
                ),
              ),
              Positioned(
                top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
                right: 16,
                left: 16,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 8,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final connectivityState = ref.watch(
                          connectivityProvider,
                        );
                        final cacheInfoAsync = ref.watch(cacheInfoProvider);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, overlayEntry),
                            const SizedBox(height: 16),
                            _buildCacheInfo(context, cacheInfoAsync),
                            const SizedBox(height: 16),
                            _buildTipContainer(context),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  static Widget _buildHeader(BuildContext context, OverlayEntry overlayEntry) {
    return Row(
      children: [
        Icon(
          Icons.cloud_off_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'App offline',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
        IconButton(
          onPressed: () => overlayEntry.remove(),
          icon: Icon(
            Icons.close_rounded,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  static Widget _buildCacheInfo(
    BuildContext context,
    AsyncValue<List<AssetCacheInfo>> cacheInfoAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preços salvos',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        cacheInfoAsync.when(
          data: (cacheInfoList) {
            if (cacheInfoList.isEmpty) {
              return Text(
                'Nenhum preço salvo disponível',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              );
            }

            return Column(
              children:
                  cacheInfoList
                      .map((info) => _buildAssetCacheRow(context, info))
                      .toList(),
            );
          },
          loading:
              () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          error:
              (error, stackTrace) => Text(
                'Erro ao carregar informações de cache',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
        ),
      ],
    );
  }

  static Widget _buildAssetCacheRow(BuildContext context, AssetCacheInfo info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Ícone do asset
          SvgPicture.asset(info.asset.iconPath, width: 32, height: 32),

          const SizedBox(width: 12),

          // Nome e status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.asset.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  info.hasCache ? info.formattedAge : 'Sem cache',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Preço
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                info.formattedPrice,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              if (info.hasCache)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getCacheStatusColor(context, info.ageInMinutes),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getCacheStatusText(info.ageInMinutes),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildTipContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Os preços serão atualizados automaticamente quando a conexão for restaurada',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else {
      return '${dateTime.day}/${dateTime.month} às ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  static Color _getCacheStatusColor(BuildContext context, int? ageInMinutes) {
    if (ageInMinutes == null) return Colors.grey;

    if (ageInMinutes < 5) {
      return Colors.green;
    } else if (ageInMinutes < 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  static String _getCacheStatusText(int? ageInMinutes) {
    if (ageInMinutes == null) return 'N/A';

    if (ageInMinutes < 5) {
      return 'Recente';
    } else if (ageInMinutes < 30) {
      return 'Antigo';
    } else {
      return 'Muito antigo';
    }
  }
}
