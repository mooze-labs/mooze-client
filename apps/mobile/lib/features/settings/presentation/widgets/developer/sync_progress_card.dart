import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart' as v2;
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/services/service_state.dart';
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

enum DeveloperOperation { lightSync, fullSync, rescan, exportLogs, clearLogs }

class SyncProgressCard extends ConsumerStatefulWidget {
  const SyncProgressCard({super.key, required this.operation});

  final DeveloperOperation operation;

  @override
  ConsumerState<SyncProgressCard> createState() => _SyncProgressCardState();
}

class _SyncProgressCardState extends ConsumerState<SyncProgressCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _rotation;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _rotation = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final colors = context.colors;

    final syncAsync = ref.watch(v2.syncStateProvider);
    final state = syncAsync.valueOrNull;
    final perChain = state?.perChain ?? const <ChainId, ServiceLifecycle>{};
    final phase = state?.phase ?? SyncPhase.running;

    final title = _titleFor(widget.operation);
    final subtitle = _stageMessage(widget.operation, phase, perChain);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, Motion.durationEmphasis),
      curve: Motion.curveEnter,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -Motion.riseDistance),
            child: child,
          ),
        );
      },
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AnimatedSyncGlyph(rotation: _rotation, color: cs.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: tt.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: Motion.of(context, Motion.durationBase),
                        switchInCurve: Motion.curveEnter,
                        switchOutCurve: Motion.curveExit,
                        child: Text(
                          subtitle,
                          key: ValueKey(subtitle),
                          style: tt.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ProgressBar(controller: _pulse, color: cs.primary),
            const SizedBox(height: 4),
            _ChainList(perChain: perChain, operation: widget.operation),
          ],
        ),
      ),
    );
  }

  String _titleFor(DeveloperOperation op) {
    switch (op) {
      case DeveloperOperation.lightSync:
        return 'Light sync in progress';
      case DeveloperOperation.fullSync:
        return 'Full sync in progress';
      case DeveloperOperation.rescan:
        return 'Rescanning onchain swaps';
      case DeveloperOperation.exportLogs:
        return 'Exporting logs';
      case DeveloperOperation.clearLogs:
        return 'Clearing logs';
    }
  }

  String _stageMessage(
    DeveloperOperation op,
    SyncPhase phase,
    Map<ChainId, ServiceLifecycle> perChain,
  ) {
    if (op == DeveloperOperation.exportLogs) {
      return 'Packaging diagnostics and writing ZIP…';
    }
    if (op == DeveloperOperation.clearLogs) {
      return 'Removing log records…';
    }
    if (phase == SyncPhase.idle) {
      return 'Preparing chains…';
    }
    // Pick the first non-connected chain to describe.
    for (final chain in const [ChainId.liquid, ChainId.bitcoin]) {
      final lc = perChain[chain];
      if (lc == ServiceLifecycle.connecting) {
        return 'Connecting to ${_chainName(chain)}…';
      }
    }
    if (op == DeveloperOperation.rescan) {
      return 'Refreshing balances, then rescanning swaps…';
    }
    if (op == DeveloperOperation.fullSync) {
      return 'Liquid → Bitcoin, then rescan';
    }
    return 'Refreshing balances and transactions…';
  }

  String _chainName(ChainId c) => switch (c) {
    ChainId.liquid => 'Liquid',
    ChainId.bitcoin => 'Bitcoin',
    ChainId.lightning => 'Lightning',
    ChainId.aggregate => 'all chains',
  };
}

class _AnimatedSyncGlyph extends StatelessWidget {
  const _AnimatedSyncGlyph({required this.rotation, required this.color});

  final AnimationController rotation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Center(
        child: RotationTransition(
          turns: rotation,
          child: Icon(Icons.sync_rounded, color: color, size: 24),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final track = AppSurfaces.hairline(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: 3,
        color: track,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            // Indeterminate "sliding" highlight bar.
            return LayoutBuilder(
              builder: (context, c) {
                final width = c.maxWidth * 0.45;
                final startX = -width + (c.maxWidth + width) * controller.value;
                return Stack(
                  children: [
                    Positioned(
                      left: startX,
                      top: 0,
                      bottom: 0,
                      width: width,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: color,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Status of each chain, as dots on one line.
class _ChainList extends StatelessWidget {
  const _ChainList({required this.perChain, required this.operation});

  final Map<ChainId, ServiceLifecycle> perChain;
  final DeveloperOperation operation;

  @override
  Widget build(BuildContext context) {
    final chains = const [ChainId.liquid, ChainId.bitcoin];
    return Row(
      children: [
        for (int i = 0; i < chains.length; i++)
          Expanded(
            child: _ChainStatus(
              chain: chains[i],
              lifecycle: perChain[chains[i]] ?? ServiceLifecycle.uninitialized,
            ),
          ),
      ],
    );
  }
}

class _ChainStatus extends StatelessWidget {
  const _ChainStatus({required this.chain, required this.lifecycle});

  final ChainId chain;
  final ServiceLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final colors = context.colors;
    final tt = context.textTheme;

    final isActive = lifecycle == ServiceLifecycle.connected;
    final isErrored = lifecycle == ServiceLifecycle.errored;
    final isWorking = lifecycle == ServiceLifecycle.connecting;

    final dotColor = isErrored
        ? cs.error
        : isActive
        ? colors.positiveColor
        : isWorking
        ? cs.primary
        : colors.textTertiary;

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          _StatusDot(color: dotColor, animating: isWorking),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _label(chain),
              style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: isErrored ? cs.error : colors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static String _label(ChainId c) => switch (c) {
    ChainId.liquid => 'Liquid',
    ChainId.bitcoin => 'Bitcoin',
    ChainId.lightning => 'Lightning',
    ChainId.aggregate => 'Aggregate',
  };
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color, required this.animating});

  final Color color;
  final bool animating;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.animating) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animating && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.animating && _c.isAnimating) {
      _c.stop();
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = widget.animating ? 0.5 + (_c.value * 0.5) : 1.0;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: t),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
