import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final int productId;
  final String nome;
  final double preco;
  int quantidade;

  CartItem({
    required this.productId,
    required this.nome,
    required this.preco,
    this.quantidade = 0,
  });

  double get total => preco * quantidade;

  CartItem copyWith({
    int? productId,
    String? nome,
    double? preco,
    int? quantidade,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      nome: nome ?? this.nome,
      preco: preco ?? this.preco,
      quantidade: quantidade ?? this.quantidade,
    );
  }
}

class CartController extends StateNotifier<Map<int, CartItem>> {
  CartController() : super({});

  void updateQuantity(
    int productId,
    String nome,
    double preco,
    bool incrementar,
  ) {
    final currentState = Map<int, CartItem>.from(state);

    if (currentState.containsKey(productId)) {
      final currentItem = currentState[productId]!;
      if (incrementar) {
        currentState[productId] = currentItem.copyWith(
          quantidade: currentItem.quantidade + 1,
        );
      } else {
        if (currentItem.quantidade > 0) {
          currentState[productId] = currentItem.copyWith(
            quantidade: currentItem.quantidade - 1,
          );
        }
        if (currentState[productId]!.quantidade == 0) {
          currentState.remove(productId);
        }
      }
    } else if (incrementar) {
      currentState[productId] = CartItem(
        productId: productId,
        nome: nome,
        preco: preco,
        quantidade: 1,
      );
    }

    state = currentState;
  }

  int getQuantityForProduct(int productId) {
    return state[productId]?.quantidade ?? 0;
  }

  double get totalCart {
    return state.values.fold(0.0, (sum, item) => sum + item.total);
  }

  void clearCart() {
    state = {};
  }

  List<CartItem> get cartItems {
    return state.values.toList();
  }
}

final cartControllerProvider =
    StateNotifierProvider<CartController, Map<int, CartItem>>((ref) {
      return CartController();
    });

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartControllerProvider);
  return cart.values.fold(0.0, (sum, item) => sum + item.total);
});
