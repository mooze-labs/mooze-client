import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mooze_mobile/features/merchant/presentation/models/item_compat.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

/// Items List Widget (Presentation Layer)
///
/// Displays a list of products/items in the merchant mode.
class ItemsListWidget extends StatelessWidget {
  /// List of products to display
  final List<Item> items;

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
    required this.items,
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
      backgroundColor: Colors.black,
      body: items.isEmpty ? _buildEmptyState() : _buildItemsList(),
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

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Nenhum produto cadastrado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Comece adicionando seu primeiro produto\nclicando no botão + abaixo',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20).copyWith(bottom: 100),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        final isFirstItem = index == 0 && firstItemKey != null;

        return Slidable(
          key: isFirstItem ? firstItemKey : Key(item.name + index.toString()),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (context) => onEditItem(index),
                backgroundColor: AppColors.editColor.withValues(alpha: 0.3),
                foregroundColor: AppColors.editColor,
                icon: Icons.edit,
              ),
              SlidableAction(
                onPressed: (context) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: const Text(
                            'Deletar item',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            'Deseja realmente deletar "${item.name}"?',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Deletar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );

                  if (confirm ?? false) {
                    onRemoveItem(index);
                  }
                },
                backgroundColor: AppColors.errorColor.withValues(alpha: 0.3),
                foregroundColor: AppColors.errorColor,
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
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
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
                      if (item.quantity > 0) {
                        onUpdateQuantity(index, false);
                      }
                    },
                    icon: Icon(
                      Icons.remove,
                      color:
                          item.quantity < 1
                              ? AppColors.errorColor.withValues(alpha: 0.3)
                              : AppColors.errorColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  Text(
                    item.quantity.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      onUpdateQuantity(index, true);
                    },
                    icon: const Icon(
                      Icons.add,
                      color: AppColors.positiveColor,
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
