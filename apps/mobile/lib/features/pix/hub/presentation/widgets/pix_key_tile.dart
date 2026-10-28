import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:share_plus/share_plus.dart';

/// One Pix key, with the actions to copy and to share it.
///
/// The row shows the masked key. The full value only leaves the screen when
/// the user copies or shares it.
class PixKeyTile extends StatelessWidget {
  final PixKey pixKey;

  /// Called when the row itself is tapped, when the screen handles it.
  final VoidCallback? onTap;

  const PixKeyTile({super.key, required this.pixKey, this.onTap});

  Future<void> _copy(BuildContext context) async {
    final t = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: pixKey.value));
    if (context.mounted) {
      AppSnackBar.success(context, t.pix_hub_key_copied);
    }
  }

  Future<void> _share(BuildContext context) async {
    final t = AppLocalizations.of(context);
    await SharePlus.instance.share(
      ShareParams(text: t.pix_hub_key_share_message(pixKey.value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final primary = context.colors.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                switch (pixKey.type) {
                  PixKeyType.cpf || PixKeyType.cnpj => Icons.badge_outlined,
                  PixKeyType.phone => Icons.phone_iphone_rounded,
                  PixKeyType.email => Icons.alternate_email_rounded,
                  PixKeyType.random => Icons.shuffle_rounded,
                },
                size: 20,
                color: primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pixKey.label ?? pixKeyTypeLabel(t, pixKey.type),
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pixKey.masked,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: t.pix_hub_copy,
              onPressed: () => _copy(context),
              icon: Icon(Icons.copy_rounded, size: 18, color: primary),
            ),
            IconButton(
              tooltip: t.pix_hub_share,
              onPressed: () => _share(context),
              icon: Icon(Icons.ios_share_rounded, size: 18, color: primary),
            ),
          ],
        ),
      ),
    );
  }
}
