import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/cart_item_entity.dart';
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
      body: products.isEmpty ? _buildEmptyState(context) : _buildItemsList(context),
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
              'Nenhum produto cadastrado',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comece adicionando seu primeiro produto\nclicando no botão + abaixo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: outline,
              ),
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
                backgroundColor: context.colors.editColor.withValues(alpha: 0.3),
                foregroundColor: context.colors.editColor,
                icon: Icons.edit,
              ),
              SlidableAction(
                onPressed: (context) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                          title: Text(
                            'Deletar item',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          content: Text(
                            'Deseja realmente deletar "${product.name}"?',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'Deletar',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                  );

                  if (confirm ?? false) {
                    onRemoveItem(index);
                  }
                },
                backgroundColor: context.colors.errorColor.withValues(alpha: 0.3),
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
