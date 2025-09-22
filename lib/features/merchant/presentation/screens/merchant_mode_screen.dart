import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/merchant/models/item.dart';
import 'package:mooze_mobile/features/merchant/models/product.dart';
import 'package:mooze_mobile/features/merchant/presentation/providers/product_controller.dart';
import 'package:mooze_mobile/features/merchant/presentation/providers/cart_provider.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_charge_screen.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/add_edit_item_modal.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/items_list_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/keypad_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_header_widget.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class MerchantModeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MerchantModeScreen> createState() => MerchantModeScreenState();
}

class MerchantModeScreenState extends ConsumerState<MerchantModeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double valorBitcoin = 0;
  String valorDigitado = '0.00';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _adicionarNumero(String numero) {
    setState(() {
      String valorLimpo = valorDigitado.replaceAll('.', '').replaceAll(',', '');
      valorLimpo += numero;
      double valor = double.parse(valorLimpo) / 100;
      valorDigitado = valor.toStringAsFixed(2);
    });
  }

  void _apagarNumero() {
    setState(() {
      if (valorDigitado.length > 1) {
        String valorLimpo = valorDigitado
            .replaceAll('.', '')
            .replaceAll(',', '');
        if (valorLimpo.length > 1) {
          valorLimpo = valorLimpo.substring(0, valorLimpo.length - 1);
          double valor = double.parse(valorLimpo) / 100;
          valorDigitado = valor.toStringAsFixed(2);
        } else {
          valorDigitado = '0.00';
        }
      } else {
        valorDigitado = '0.00';
      }
    });
  }

  void _adicionarAoTotal() {
    setState(() {
      double valorAdicionado = double.tryParse(valorDigitado) ?? 0.0;
      if (valorAdicionado > 0) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        ref
            .read(cartControllerProvider.notifier)
            .updateQuantity(timestamp, 'Valor Avulso', valorAdicionado, true);
      }
      valorDigitado = '0.00';
    });
  }

  Future<void> _adicionarItem(Item item) async {
    try {
      final product = ProductEntity(
        name: item.nome,
        price: item.preco,
        createdAt: DateTime.now(),
      );

      await ref.read(productControllerProvider.notifier).addProduct(product);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar produto: $e')),
        );
      }
    }
  }

  Future<void> _editarItem(int index) async {
    final productsAsync = ref.read(productControllerProvider);
    final products = productsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <ProductEntity>[],
    );

    if (index >= products.length) return;

    final product = products[index];
    final item = Item(nome: product.name, preco: product.price, quantidade: 0);

    AddEditItemModal.mostrarBottomSheetEditar(context, item, (
      Item itemEditado,
    ) async {
      try {
        final updatedProduct = product.copyWith(
          name: itemEditado.nome,
          price: itemEditado.preco,
        );

        await ref
            .read(productControllerProvider.notifier)
            .updateProduct(updatedProduct);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto atualizado com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar produto: $e')),
          );
        }
      }
    });
  }

  Future<void> _removerItem(int index) async {
    try {
      final productsAsync = ref.read(productControllerProvider);
      final products = productsAsync.maybeWhen(
        data: (data) => data,
        orElse: () => <ProductEntity>[],
      );

      if (index >= products.length) return;

      final product = products[index];
      if (product.id != null) {
        await ref
            .read(productControllerProvider.notifier)
            .removeProduct(product.id!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto removido com sucesso!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao remover produto: $e')));
      }
    }
  }

  void _atualizarQuantidade(int index, bool incrementar) {
    final productsAsync = ref.read(productControllerProvider);
    final products = productsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <ProductEntity>[],
    );

    if (index >= products.length) return;

    final product = products[index];
    if (product.id != null) {
      ref
          .read(cartControllerProvider.notifier)
          .updateQuantity(
            product.id!,
            product.name,
            product.price,
            incrementar,
          );
    }
  }

  void _mostrarBottomSheetAdicionar() {
    AddEditItemModal.mostrarBottomSheetAdicionar(context, _adicionarItem);
  }

  void _finalizarVenda() {
    final cartTotal = ref.read(cartTotalProvider);
    final cartItems = ref.read(cartControllerProvider.notifier).cartItems;

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Adicione itens ao carrinho antes de finalizar a venda',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (cartTotal < 20.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O valor mínimo para finalizar a venda é de R\$ 20,00'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => MerchantChargeScreen(
                  totalAmount: cartTotal,
                  items: cartItems,
                ),
          ),
        )
        .then((_) {
          ref.read(cartControllerProvider.notifier).clearCart();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEA1E63), Color(0xFF841138)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Consumer(
                  builder: (context, ref, child) {
                    final valorReais = ref.watch(cartTotalProvider);
                    return MerchantHeaderWidget(
                      valorReais: valorReais,
                      valorBitcoin: valorBitcoin,
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 16),
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.pink,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey[400],
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [Icon(Icons.grid_3x3), Text('Keypad')],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [Icon(Icons.grid_3x3), Text('Itens')],
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            KeypadWidget(
                              valorDigitado: valorDigitado,
                              onAdicionarNumero: _adicionarNumero,
                              onApagarNumero: _apagarNumero,
                              onAdicionarAoTotal: _adicionarAoTotal,
                              onFinalizarVenda: _finalizarVenda,
                              cartTotal: ref.watch(cartTotalProvider),
                            ),
                            Consumer(
                              builder: (context, ref, child) {
                                final productsAsync = ref.watch(
                                  productControllerProvider,
                                );

                                return productsAsync.when(
                                  data: (products) {
                                    return Consumer(
                                      builder: (context, ref, child) {
                                        final items =
                                            products.map((product) {
                                              final quantidade =
                                                  product.id != null
                                                      ? ref
                                                          .read(
                                                            cartControllerProvider
                                                                .notifier,
                                                          )
                                                          .getQuantityForProduct(
                                                            product.id!,
                                                          )
                                                      : 0;

                                              return Item(
                                                nome: product.name,
                                                preco: product.price,
                                                quantidade: quantidade,
                                              );
                                            }).toList();

                                        return ItemsListWidget(
                                          produtos: items,
                                          onEditarItem: _editarItem,
                                          onRemoverItem: _removerItem,
                                          onAtualizarQuantidade:
                                              _atualizarQuantidade,
                                          onAdicionarItem:
                                              _mostrarBottomSheetAdicionar,
                                        );
                                      },
                                    );
                                  },
                                  loading:
                                      () => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                  error:
                                      (error, stackTrace) => Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.error,
                                              color: Colors.red,
                                              size: 48,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Erro ao carregar produtos',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              error.toString(),
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: () {
                                                ref.invalidate(
                                                  productControllerProvider,
                                                );
                                              },
                                              child: const Text(
                                                'Tentar novamente',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
