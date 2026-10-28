import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_recipient.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Round avatar with the initials of a recipient.
class PixRecipientAvatar extends StatelessWidget {
  final PixRecipient recipient;
  final double size;

  const PixRecipientAvatar({
    super.key,
    required this.recipient,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primaryColor;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Text(
        recipient.initials,
        style: context.textTheme.titleMedium?.copyWith(
          color: primary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

/// Compact recipient entry used by the horizontal list of the hub home.
class PixRecipientChip extends StatelessWidget {
  final PixRecipient recipient;
  final VoidCallback onTap;

  const PixRecipientChip({
    super.key,
    required this.recipient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: recipient.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              children: [
                PixRecipientAvatar(recipient: recipient),
                const SizedBox(height: 8),
                Text(
                  recipient.name.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colors.textSecondary,
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

/// Full-width recipient row used by the recipient picker.
///
/// Leave [onTap] null to show the recipient without making the row tappable,
/// as the review steps do.
class PixRecipientTile extends StatelessWidget {
  final PixRecipient recipient;
  final VoidCallback? onTap;

  const PixRecipientTile({super.key, required this.recipient, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            PixRecipientAvatar(recipient: recipient, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipient.name,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${recipient.institution} · ${recipient.maskedDocument}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.colors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
