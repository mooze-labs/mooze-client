import 'package:flutter/material.dart';

class InfoOverlay {
  static void show(
    BuildContext context, {
    required String title,
    required List<InfoStep> steps,
    Widget Function(VoidCallback closeOverlay)? footerBuilder,
  }) {
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
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
                        ),
                        const SizedBox(height: 16),
                        ...steps.asMap().entries.map((entry) {
                          final isLast = entry.key == steps.length - 1;
                          return Column(
                            children: [
                              _buildInfoStep(context, entry.value),
                              if (!isLast) const SizedBox(height: 12),
                            ],
                          );
                        }),
                        if (footerBuilder != null) ...[
                          const SizedBox(height: 16),
                          footerBuilder(() => overlayEntry.remove()),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.3),
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
                                  'Toque fora desta área para fechar',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  static Widget _buildInfoStep(BuildContext context, InfoStep step) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (step.number != null)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.number!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else if (step.icon != null)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color:
                  step.iconColor ??
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              size: 14,
              color: step.iconColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                step.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InfoStep {
  final String? number;
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String description;

  InfoStep({
    this.number,
    this.icon,
    this.iconColor,
    required this.title,
    required this.description,
  }) : assert(
         (number != null && icon == null) || (number == null && icon != null),
         'Either number or icon must be provided, but not both',
       );
}
