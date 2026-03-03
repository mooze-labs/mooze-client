import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/cart_item_entity.dart';
import 'package:mooze_mobile/features/merchant/domain/usecases/manage_cart_usecase.dart';

/// Cart Controller (Presentation Layer)
///
/// Manages the shopping cart state using Riverpod's StateNotifier.
/// This controller acts as a bridge between the UI and the business logic (use cases),
///

class CartController extends StateNotifier<Map<int, CartItemEntity>> {
  final ManageCartUseCase _manageCartUseCase;

  CartController(this._manageCartUseCase) : super({});

  /// Updates the quantity of a product in the cart

  /// When [increment] is true, adds 1 unit to the cart.
  /// When false, removes 1 unit (or removes the item if quantity becomes 0).
  void updateQuantity(
    int productId,
    String name,
    double price,
    bool increment,
  ) {
    if (increment) {
      state = _manageCartUseCase.addItem(state, productId, name, price);
    } else {
      state = _manageCartUseCase.removeItem(state, productId);
    }
  }

  /// Gets the quantity of a specific product in the cart
  ///
  /// Returns: Quantity in cart, or 0 if product not found
  int getQuantityForProduct(int productId) {
    return _manageCartUseCase.getQuantityForProduct(state, productId);
  }

  /// Calculates and returns the total value of the cart
  ///
  /// Returns: Sum of (price * quantity) for all items in BRL
  double get totalCart {
    return _manageCartUseCase.calculateTotal(state);
  }

  /// Clears all items from the cart
  ///
  /// Sets the state to an empty map
  void clearCart() {
    state = _manageCartUseCase.clearCart();
  }

  /// Gets all cart items as a list
  ///
  /// Returns: List of CartItemEntity for UI rendering
  List<CartItemEntity> get cartItems {
    return _manageCartUseCase.getCartItems(state);
  }
}

/// Cart Controller Provider
///
/// Provides a single instance of CartController to the widget tree.
/// The state (Map<int, CartItemEntity>) is automatically managed by Riverpod.
final cartControllerProvider =
    StateNotifierProvider<CartController, Map<int, CartItemEntity>>((ref) {
      final manageCartUseCase = ManageCartUseCase();
      return CartController(manageCartUseCase);
    });

/// Cart Total Provider
///
/// Calculates the total value of the cart reactively.
///
/// IMPORTANT: This provider watches the cart STATE (not the notifier),
/// so it automatically recalculates whenever items are added/removed.
///
/// Returns: Total cart value in BRL
final cartTotalProvider = Provider<double>((ref) {
  // Watch the cart state - this triggers rebuild when cart changes
  final cart = ref.watch(cartControllerProvider);
  final manageCartUseCase = ManageCartUseCase();
  return manageCartUseCase.calculateTotal(cart);
});
