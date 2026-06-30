import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/cart_item_entity.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Items List Widget (Presentation Layer)
///
/// Displays a list of products/items in the merchant mode.
/// Shows products with their current quantities from the cart.
///
/// Features:
/// - Empty state when no products are available
/// - Slidable list items with swipe actions (edit/delete)
/// - Quantity increment/decrement buttons
/// - Floating action button to add new products
///
/// Each list item shows:
/// - Product name and price
/// - Current quantity in cart
/// - Total price for that item (price × quantity)
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

  /// Callback when floating action button (add product) is pressed
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
    return Scaffold(
      backgroundColor: context.colors.backgroundColor,
      body:
          products.isEmpty
              ? _buildEmptyState(context)
              : _buildItemsList(context),
      floatingActionButton: SizedBox(
        key: addButtonKey,
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: onAddItem,
          backgroundColor: const Color(0xFFE91E63),
          elevation: 8,
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final t = AppLocalizations.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final outline = Theme.of(context).colorScheme.outline;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: outline),
            const SizedBox(height: 20),
            Text(
              t.merchant_no_products_title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.merchant_no_products_body,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20).copyWith(bottom: 100),
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final product = products[index];
        final isFirstItem = index == 0 && firstItemKey != null;

        // Get quantity from cart (0 if product not in cart)
        final quantity =
            product.id != null ? (cart[product.id!]?.quantity ?? 0) : 0;

        return Slidable(
          key: isFirstItem ? firstItemKey : Key('${product.name}_$index'),
          endActionPane: ActionPane(
            motion: ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (context) => onEditItem(index),
                backgroundColor: context.colors.editColor.withValues(
                  alpha: 0.3,
                ),
                foregroundColor: context.colors.editColor,
                icon: Icons.edit,
              ),
              SlidableAction(
                onPressed: (context) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      final t = AppLocalizations.of(context);
                      return Dialog(
                        backgroundColor: context.colors.backgroundCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: context.colors.errorColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: context.colors.errorColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                t.merchant_delete_item_title,
                                style: context.textTheme.titleMedium?.copyWith(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.merchant_delete_item_confirm(product.name),
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colors.textSecondary,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            context.colors.textPrimary,
                                        side: BorderSide(
                                          color: context.colors.textPrimary
                                              .withValues(alpha: 0.2),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text(t.common_cancel),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            context.colors.errorColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text(t.merchant_delete_action),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  if (confirm ?? false) {
                    onRemoveItem(index);
                  }
                },
                backgroundColor: context.colors.errorColor.withValues(
                  alpha: 0.3,
                ),
                foregroundColor: context.colors.errorColor,
                icon: Icons.delete,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${product.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      if (quantity > 0) {
                        onUpdateQuantity(index, false);
                      }
                    },
                    icon: Icon(
                      Icons.remove,
                      color:
                          quantity < 1
                              ? context.colors.errorColor.withValues(alpha: 0.3)
                              : context.colors.errorColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  Text(
                    quantity.toString(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      onUpdateQuantity(index, true);
                    },
                    icon: Icon(
                      Icons.add,
                      color: context.colors.positiveColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
