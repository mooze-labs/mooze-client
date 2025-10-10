import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:mooze_mobile/features/wallet_level/domain/entities/wallet_level_entity.dart';

class LevelSectionsList extends StatefulWidget {
  final ColorScheme colorScheme;
  final bool isLoading;
  final List<WalletLevelEntity> levels;

  const LevelSectionsList({
    super.key,
    required this.colorScheme,
    this.isLoading = false,
    this.levels = const [],
  });

  @override
  State<LevelSectionsList> createState() => _LevelSectionsListState();
}

class _LevelSectionsListState extends State<LevelSectionsList> {
  final List<bool> _expandedSections = List.filled(4, false);
  final String _nivelAtual = "Prata";

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingLevelSections();
    }

    return Column(
      children: [..._buildLevelSections(Theme.of(context), widget.colorScheme)],
    );
  }

  List<Widget> _buildLevelSections(ThemeData theme, ColorScheme colorScheme) {
    final levels = widget.levels;
    return levels.asMap().entries.map((entry) {
      final index = entry.key;
      final level = entry.value;
      final isCurrentLevel = level.title == _nivelAtual;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          elevation: isCurrentLevel ? 2 : 0,
          color:
              isCurrentLevel
                  ? level.levelColor.withValues(alpha: 0.05)
                  : colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  isCurrentLevel
                      ? level.levelColor.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.2),
              width: isCurrentLevel ? 2 : 1,
            ),
          ),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _expandedSections[index],
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedSections[index] = expanded;
                });
              },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: level.levelColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(level.icon, color: Colors.white, size: 22),
              ),
              title: Row(
                children: [
                  Text(
                    level.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (isCurrentLevel) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: level.levelColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ATUAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    'Limite diário: R\$ ${level.limits.maxLimitInReais.toStringAsFixed(0)} • Máximo: R\$ ${level.limits.maxLimitInReais.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: level.levelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getPreview(level.description),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          level.description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: level.levelColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: level.levelColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 16,
                                  color: level.levelColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Limites do Nível',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildLevelLimitCard(
                                    'Mínimo',
                                    'R\$ ${level.limits.minLimitInReais.toStringAsFixed(0)}',
                                    Icons.trending_down,
                                    level.levelColor,
                                    colorScheme,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildLevelLimitCard(
                                    'Máximo',
                                    'R\$ ${level.limits.maxLimitInReais.toStringAsFixed(0)}',
                                    Icons.trending_up,
                                    level.levelColor,
                                    colorScheme,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (level.benefits.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: level.levelColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Benefícios',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...level.benefits.map(
                                (beneficio) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(
                                          top: 6,
                                          right: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: level.levelColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          beneficio,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.8),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLevelLimitCard(
    String title,
    String value,
    IconData icon,
    Color levelColor,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: levelColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: levelColor),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _getPreview(String content) {
    return content.length > 80 ? '${content.substring(0, 80)}...' : content;
  }

  Widget _buildLoadingLevelSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...List.generate(3, (index) => _buildLoadingLevelCard())],
    );
  }

  Widget _buildLoadingLevelCard() {
    final baseColor = AppColors.baseColor;
    final highlightColor = AppColors.highlightColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
