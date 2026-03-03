import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/merchant/presentation/controllers/controllers.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_charge_screen.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/add_edit_item_modal.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/items_list_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/keypad_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_header_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/finalizar_venda_button.dart';
import 'package:mooze_mobile/features/merchant/presentation/services/merchant_tutorial_service.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Merchant Mode Screen (Presentation Layer)
///
/// The main screen for merchant mode - allows businesses to create charges
/// and accept payments from customers.
///

class MerchantModeScreen extends ConsumerStatefulWidget {
  final String? origin;

  const MerchantModeScreen({super.key, this.origin});

  @override
  ConsumerState<MerchantModeScreen> createState() => MerchantModeScreenState();
}

class MerchantModeScreenState extends ConsumerState<MerchantModeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String valorDigitado = '0.00';

  // GlobalKeys
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _valorTotalKey = GlobalKey();
  final GlobalKey _valorInputKey = GlobalKey();
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey _itemsTabKey = GlobalKey();
  final GlobalKey _addProductButtonKey = GlobalKey();
  final GlobalKey _adicionarModalButtonKey = GlobalKey();
  final GlobalKey _firstProductKey = GlobalKey();
  final GlobalKey _finalizarVendaKey = GlobalKey();
  final GlobalKey _limparKey = GlobalKey();

  TutorialCoachMark? _tutorialCoachMark;
  final _tutorialService = MerchantTutorialService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // _tutorialService.resetTutorial();

    // Mark that we're in merchant mode
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final merchantModeService = ref.read(merchantModeServiceProvider);
      // Save the origin (where we came from)
      final originRoute = widget.origin ?? '/home';
      await merchantModeService.setMerchantModeActive(
        true,
        origin: originRoute,
      );

      final tutorialShown = await _tutorialService.isTutorialShown();
      if (!tutorialShown && mounted) {
        _showTutorial();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tutorialCoachMark?.finish();
    super.dispose();
  }

  void _showTutorial() {
    setState(() {
      valorDigitado = '20.00';
    });

    _tutorialCoachMark = TutorialCoachMark(
      targets: _createTutorialTargets(),
      colorShadow: Colors.green,
      paddingFocus: 10,
      opacityShadow: 0.8,
      alignSkip: Alignment.topRight,
      onClickOverlay: (target) {},
      onClickTarget: (target) async {
        if (target.identify == "add_button") {
          _adicionarAoTotal();
        } else if (target.identify == "items_tab") {
          _tabController.animateTo(1);
        } else if (target.identify == "add_product") {
          // Add tutorial product
          final product = ProductEntity(
            name: 'Produto 01',
            price: 21.00,
            createdAt: DateTime.now(),
          );
          await _adicionarItem(product);

          Future.delayed(Duration(milliseconds: 600), () {
            if (mounted) {
              _tutorialCoachMark?.next();
            }
          });
        }
      },
      onFinish: () async {
        await _tutorialService.setTutorialShown();
      },
      onSkip: () {
        _tutorialService.setTutorialShown();
        _limparDadosTutorial();
        return true;
      },
    );

    _tutorialCoachMark?.show(context: context);
  }

  List<TargetFocus> _createTutorialTargets() {
    List<TargetFocus> targets = [];
    targets.add(
      TargetFocus(
        identify: "welcome",
        targetPosition: TargetPosition(
          Size(MediaQuery.of(context).size.width * 0.9, 200),
          Offset(
            MediaQuery.of(context).size.width * 1.5,
            MediaQuery.of(context).size.height * 0.2,
          ),
        ),
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bem-vindo ao Modo Comerciante!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Aqui você tem um mini PDV: cadastre itens, some valores e cobre seus clientes de forma rápida.",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.next();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE91E63),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Continuar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "valor_input",
        keyTarget: _valorInputKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Digite o valor desejado",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Vamos começar inserindo um valor de R\$ 20,00 usando o teclado abaixo.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "add_button",
        keyTarget: _addButtonKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Adicionar valor",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Agora toque no botão '+' verde para adicionar o valor à lista de itens.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "items_tab",
        keyTarget: _itemsTabKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Aba de Itens",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Toque aqui para ver seus produtos cadastrados e criar novos itens.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "add_product",
        keyTarget: _addProductButtonKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Criar produto",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Toque no botão '+' para criar automaticamente o produto 'Produto 01' com preço de R\$ 21,00.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "manage_products",
        keyTarget: _firstProductKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Editar e Deletar produtos",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Arraste este produto da direita para a esquerda para ver as opções de editar ✏️ e excluir 🗑️.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "finalizar_venda",
        keyTarget: _finalizarVendaKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Finalizar venda",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Quando tiver itens no carrinho (mínimo R\$ 20,00), toque aqui para finalizar a venda.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "limpar",
        keyTarget: _limparKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Limpar carrinho",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Se quiser começar do zero, toque aqui para limpar todos os itens do carrinho.",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "conclusion",
        targetPosition: TargetPosition(
          Size(MediaQuery.of(context).size.width * 0.9, 200),
          Offset(
            MediaQuery.of(context).size.width * 1.5,
            MediaQuery.of(context).size.height * 0.2,
          ),
        ),
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tutorial Concluído! 🎉",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Agora você já sabe usar todas as funcionalidades do Modo Comerciante. Pronto para começar?",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              controller.skip();
                              await _limparDadosTutorial();
                              await _tutorialService.resetTutorial();
                              if (mounted) {
                                _showTutorial();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.white, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Refazer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await _limparDadosTutorial();
                              controller.next();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFE91E63),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Concluir',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    return targets;
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

  void _limparValor() {
    ref.read(cartControllerProvider.notifier).clearCart();
  }

  Future<void> _limparDadosTutorial() async {
    try {
      ref.read(cartControllerProvider.notifier).clearCart();

      final productsAsync = ref.read(productControllerProvider);
      final products = productsAsync.maybeWhen(
        data: (data) => data,
        orElse: () => <ProductEntity>[],
      );

      for (var product in products) {
        if (product.name == 'Produto 01' && product.price == 21.00) {
          if (product.id != null) {
            await ref
                .read(productControllerProvider.notifier)
                .removeProduct(product.id!);
          }
        }
      }

      _tabController.animateTo(0);

      if (mounted) {
        setState(() {
          valorDigitado = '0.00';
        });
      }
    } catch (e) {
      // Silently ignore errors during tutorial data cleanup
    }
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

  /// Adds a product to the database
  Future<void> _adicionarItem(ProductEntity product) async {
    try {
      await ref.read(productControllerProvider.notifier).addProduct(product);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar produto: $e')),
        );
      }
    }
  }

  /// Opens edit modal for a product at the given index
  Future<void> _editarItem(int index) async {
    final productsAsync = ref.read(productControllerProvider);
    final products = productsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <ProductEntity>[],
    );

    if (index >= products.length) return;

    final product = products[index];

    AddEditItemModal.mostrarBottomSheetEditar(context, product, (
      ProductEntity updatedProduct,
    ) async {
      try {
        await ref
            .read(productControllerProvider.notifier)
            .updateProduct(updatedProduct);
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

  /// Shows the add product modal
  void _mostrarBottomSheetAdicionar({String? nome, String? preco}) {
    AddEditItemModal.mostrarBottomSheetAdicionar(
      context,
      _adicionarItem,
      nomePadrao: nome,
      precoPadrao: preco,
      adicionarButtonKey: _adicionarModalButtonKey,
    );
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

  Future<void> _handleWillPop() async {
    // Navigate to exit screen instead of PIN verification
    context.push('/merchant/exit');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleWillPop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEA1E63), Color(0xFF841138)],
            ),
          ),
          child: PlatformSafeArea(
            iosTop: true,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                  ).copyWith(top: 10),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final valorReais = ref.watch(cartTotalProvider);
                      return Container(
                        key: _headerKey,
                        child: MerchantHeaderWidget(
                          totalAmountInBRL: valorReais,
                          onClearCart: _limparValor,
                          onBack: _handleWillPop,
                          clearButtonKey: _limparKey,
                          totalAmountKey: _valorTotalKey,
                        ),
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
                                children: [
                                  Icon(Icons.grid_3x3),
                                  Text('Keypad'),
                                ],
                              ),
                            ),
                            Tab(
                              key: _itemsTabKey,
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
                                typedValue: valorDigitado,
                                onAddDigit: _adicionarNumero,
                                onDeleteDigit: _apagarNumero,
                                onAddToTotal: _adicionarAoTotal,
                                valueInputKey: _valorInputKey,
                                addButtonKey: _addButtonKey,
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
                                          final cart = ref.watch(
                                            cartControllerProvider,
                                          );

                                          return ItemsListWidget(
                                            products: products,
                                            cart: cart,
                                            onEditItem: _editarItem,
                                            onRemoveItem: _removerItem,
                                            onUpdateQuantity:
                                                _atualizarQuantidade,
                                            onAddItem:
                                                _mostrarBottomSheetAdicionar,
                                            addButtonKey: _addProductButtonKey,
                                            firstItemKey: _firstProductKey,
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
                Consumer(
                  builder: (context, ref, child) {
                    final cartTotal = ref.watch(cartTotalProvider);
                    return FinalizarVendaButton(
                      onPressed: _finalizarVenda,
                      totalOrderAmount: cartTotal,
                      buttonKey: _finalizarVendaKey,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
