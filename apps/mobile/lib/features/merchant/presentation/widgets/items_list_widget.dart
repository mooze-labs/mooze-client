import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/cart_item_entity.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_confirm_dialog.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_flow_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_empty_state.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/shared/widgets/motion/skeleton.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Side margin of the items tab.
const double _gutter = 20;

/// Space below the list, so the floating add button never hides a row.
const double _floatingButtonClearance = 96;

/// Items List Widget (Presentation Layer)
///
/// Displays a list of products/items in the merchant mode.
/// Shows products with their current quantities from the cart.
///
/// Features:
/// - Empty state when no products are available
/// - Slidable list items with swipe actions (edit/delete)
/// - Quantity stepper on each row
/// - A floating glass button to add new products
///
/// The products sit in one glass panel, split by hairlines. Screen readers
/// read each row as one adjustable item: swipe up or down to change the
/// quantity, and use the actions menu to edit or delete the product.
///
/// Uses flutter_slidable for swipe-to-edit/delete functionality.
class ItemsListWidget extends StatelessWidget {
  /// List of products to display
  final List<ProductEntity> products;

  /// Cart state mapping product ID to cart items (for quantity display)
  final Map<int, CartItemEntity> cart;

  /// Callback when user taps edit button for an item
  /// Parameter: product index to edit
  final Function(int) onEditItem;

  /// Callback when user taps delete button for an item
  /// Parameter: product index to remove
  final Function(int) onRemoveItem;

  /// Callback when quantity is changed (+ or - buttons)
  /// Parameters: product index, increment (true) or decrement (false)
  final Function(int, bool) onUpdateQuantity;

  /// Callback when the add button is pressed
  final VoidCallback onAddItem;

  /// Global key for the add button (used for tutorials)
  final GlobalKey? addButtonKey;

  /// Global key for the first product (used for tutorials)
  final GlobalKey? firstItemKey;

  const ItemsListWidget({
    super.key,
    required this.products,
    required this.cart,
    required this.onEditItem,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    required this.onAddItem,
    this.addButtonKey,
    this.firstItemKey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: products.isEmpty
              ? _buildEmptyState(context)
              : _buildItemsList(context),
        ),
        Positioned(
          right: _gutter,
          bottom: 16,
          child: _AddProductButton(key: addButtonKey, onPressed: onAddItem),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          _gutter,
          0,
          _gutter,
          _floatingButtonClearance,
        ),
        child: PixEmptyState(
          icon: PixIcons.tag,
          title: t.merchant_no_products_title,
          message: t.merchant_no_products_body,
        ),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        _gutter,
        12,
        _gutter,
        _floatingButtonClearance,
      ),
      children: [
        GlassPanel(
          child: Column(
            children: [
              for (var index = 0; index < products.length; index++) ...[
                if (index > 0) const PanelDivider(indent: 16),
                _ProductRow(
                  slidableKey: index == 0 && firstItemKey != null
                      ? firstItemKey!
                      : Key('${products[index].name}_$index'),
                  product: products[index],
                  quantity: _quantityOf(products[index]),
                  onEdit: () => onEditItem(index),
                  onRemove: () => onRemoveItem(index),
                  onIncrease: () => onUpdateQuantity(index, true),
                  onDecrease: () => onUpdateQuantity(index, false),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Quantity of [product] in the cart. 0 if the product is not in the cart.
  int _quantityOf(ProductEntity product) =>
      product.id != null ? (cart[product.id!]?.quantity ?? 0) : 0;
}

/// Placeholder of the items tab while the products load.
class ItemsListSkeleton extends StatelessWidget {
  const ItemsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).common_loading,
      excludeSemantics: true,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(_gutter, 12, _gutter, 0),
        children: [
          GlassPanel(
            child: SkeletonShimmer(
              child: Column(
                children: [
                  for (var index = 0; index < 3; index++) ...[
                    if (index > 0) const PanelDivider(indent: 16),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 12, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonBox(width: 140, height: 14),
                                SizedBox(height: 8),
                                SkeletonBox(width: 72, height: 12),
                              ],
                            ),
                          ),
                          SkeletonBox(width: 108, height: 36, radius: 18),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Says that the products did not load, with a retry.
class ItemsListError extends StatelessWidget {
  const ItemsListError({
    super.key,
    required this.details,
    required this.onRetry,
  });

  /// The reason, already in words for the user.
  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: _gutter),
        child: PixEmptyState(
          icon: PixIcons.error,
          title: t.merchant_load_products_error,
          message: details,
          actionLabel: t.common_retry,
          onAction: onRetry,
        ),
      ),
    );
  }
}

/// One product: its name and price, and a quantity stepper.
///
/// A swipe to the left shows the edit and delete actions. Delete asks for a
/// confirmation first.
class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.slidableKey,
    required this.product,
    required this.quantity,
    required this.onEdit,
    required this.onRemove,
    required this.onIncrease,
    required this.onDecrease,
  });

  /// Key of the [Slidable]. The first row uses the tutorial key.
  final Key slidableKey;
  final ProductEntity product;
  final int quantity;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  Future<void> _confirmRemove(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showMerchantConfirmDialog(
      context,
      title: t.merchant_delete_item_title,
      message: t.merchant_delete_item_confirm(product.name),
      confirmLabel: t.merchant_delete_action,
    );
    if (confirmed) onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final priceText = formatBrlCents(merchantCents(product.price));
    final colorScheme = context.colorScheme;
    final canDecrease = quantity > 0;

    return Semantics(
      container: true,
      label: '${product.name}, $priceText',
      // An adjustable node always has a value, zero included.
      value: t.merchant_qty_prefix(quantity),
      increasedValue: t.merchant_qty_prefix(quantity + 1),
      decreasedValue: canDecrease ? t.merchant_qty_prefix(quantity - 1) : null,
      onIncrease: onIncrease,
      onDecrease: canDecrease ? onDecrease : null,
      customSemanticsActions: {
        CustomSemanticsAction(label: t.merchant_edit_action): onEdit,
        CustomSemanticsAction(label: t.merchant_delete_action): () =>
            _confirmRemove(context),
      },
      excludeSemantics: true,
      child: Slidable(
        key: slidableKey,
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.5,
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: GlassStyle.of(context).lensFill,
              foregroundColor: context.colors.textPrimary,
              icon: Icons.edit_outlined,
              label: t.merchant_edit_action,
            ),
            // White on the error color keeps the label above 4.5:1.
            SlidableAction(
              onPressed: _confirmRemove,
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              icon: Icons.delete_outline_rounded,
              label: t.merchant_delete_action,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      priceText,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _QuantityStepper(
                quantity: quantity,
                onIncrease: onIncrease,
                onDecrease: canDecrease ? onDecrease : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minus, the quantity, and plus.
///
/// A new quantity fades and scales in over [Motion.durationFast]. With
/// reduced motion it changes at once.
class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  final int quantity;
  final VoidCallback onIncrease;

  /// Null while the quantity is zero.
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) {
    final inCart = quantity > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(icon: Icons.remove_rounded, onPressed: onDecrease),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 28),
          child: AnimatedSwitcher(
            duration: Motion.of(context, Motion.durationFast),
            switchInCurve: Motion.curveEnter,
            switchOutCurve: Motion.curveExit,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              '$quantity',
              key: ValueKey(quantity),
              textAlign: TextAlign.center,
              style: context.textTheme.titleSmall?.copyWith(
                color: inCart
                    ? context.colors.textPrimary
                    : context.colors.textTertiary,
                fontWeight: inCart ? FontWeight.w700 : FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        _StepButton(icon: Icons.add_rounded, onPressed: onIncrease),
      ],
    );
  }
}

/// A round glass well with a minus or a plus. The touch target is 48 pt.
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox.square(
      dimension: 48,
      child: Center(
        child: PressScale(
          scale: Motion.pressScaleCircle,
          child: Material(
            type: MaterialType.transparency,
            child: Ink(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GlassStyle.of(context).lensFill,
                border: Border.all(color: AppSurfaces.hairline(context)),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled
                      ? context.colors.textPrimary
                      : context.colors.textTertiary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The floating glass button that adds a product.
///
/// The list scrolls under it, so it is the one surface of the screen with
/// a real backdrop blur.
class _AddProductButton extends StatelessWidget {
  const _AddProductButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).merchant_add_product_title;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: PressScale(
        child: LiquidGlass(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onPressed,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PixIcon(
                        PixIcons.add,
                        size: 20,
                        color: context.colors.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: context.colors.textPrimary,
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
