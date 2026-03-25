import 'package:mooze_mobile/features/merchant/domain/entities/cart_item_entity.dart';

/// Use Case: Manage Shopping Cart

class ManageCartUseCase {
  /// Adds one unit of a product to the cart

  Map<int, CartItemEntity> addItem(
    Map<int, CartItemEntity> currentCart,
    int productId,
    String name,
    double price,
  ) {
    final updatedCart = Map<int, CartItemEntity>.from(currentCart);

    if (updatedCart.containsKey(productId)) {
      final currentItem = updatedCart[productId]!;
      updatedCart[productId] = currentItem.copyWith(
        quantity: currentItem.quantity + 1,
      );
    } else {
      updatedCart[productId] = CartItemEntity(
        productId: productId,
        name: name,
        price: price,
        quantity: 1,
      );
    }

    return updatedCart;
  }

  /// Removes one unit of a product from the cart
  ///
  /// If the product has quantity > 1, decrements the quantity by 1.
  /// If the product has quantity = 1, removes it entirely from the cart.
  ///
  /// Parameters:
  /// - [currentCart]: Current state of the cart
  /// - [productId]: Unique identifier for the product to remove
  ///
  /// Returns: New cart state with the updated/removed item
  Map<int, CartItemEntity> removeItem(
    Map<int, CartItemEntity> currentCart,
    int productId,
  ) {
    final updatedCart = Map<int, CartItemEntity>.from(currentCart);

    if (updatedCart.containsKey(productId)) {
      final currentItem = updatedCart[productId]!;
      if (currentItem.quantity > 1) {
        updatedCart[productId] = currentItem.copyWith(
          quantity: currentItem.quantity - 1,
        );
      } else {
        updatedCart.remove(productId);
      }
    }

    return updatedCart;
  }

  /// Calculates the total price of all items in the cart
  ///
  /// Sums up the total (price * quantity) of each cart item.
  ///
  /// Returns: Total cart value in BRL
  double calculateTotal(Map<int, CartItemEntity> cart) {
    return cart.values.fold(0.0, (sum, item) => sum + item.total);
  }

  /// Clears all items from the cart
  ///
  /// Returns: Empty cart (empty Map)
  Map<int, CartItemEntity> clearCart() {
    return {};
  }

  /// Gets the quantity of a specific product in the cart
  ///
  /// Parameters:
  /// - [cart]: Current cart state
  /// - [productId]: Product to check
  ///
  /// Returns: Quantity in cart, or 0 if product is not in cart
  int getQuantityForProduct(Map<int, CartItemEntity> cart, int productId) {
    return cart[productId]?.quantity ?? 0;
  }

  /// Gets all cart items as a list
  ///
  /// Useful for displaying cart contents in the UI.
  ///
  /// Returns: List of all CartItemEntity in the cart
  List<CartItemEntity> getCartItems(Map<int, CartItemEntity> cart) {
    return cart.values.toList();
  }
}
