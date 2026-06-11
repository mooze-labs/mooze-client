import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/cart_item_entity.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/merchant/presentation/controllers/controllers.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_charge_screen.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/add_edit_item_modal.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/items_list_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/keypad_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_header_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/finalizar_venda_button.dart';
import 'package:mooze_mobile/features/merchant/presentation/services/merchant_tutorial_service.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
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

  // Caps the typed value at R$ 9.999,99 (six cent-digits). Pix transactions
  // are limited to R$ 3.000,00, so a higher input has no real-world meaning.
  static const double _kMaxKeypadValue = 9999.99;

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
      // Activate merchant mode using Clean Architecture use case
      final activateUseCase = ref.read(activateMerchantModeUseCaseProvider);
      final originRoute = widget.origin ?? '/home';
      await activateUseCase(origin: originRoute);

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
      opacityShadow: 0.95,
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
            name: AppLocalizations.of(context).merchant_default_product_name,
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
    final t = AppLocalizations.of(context);
    List<TargetFocus> targets = [];
    targets.add(
      TargetFocus(
        identify: "welcome",
        targetPosition: TargetPosition(
          Size(MediaQuery.of(context).size.width * 0.9, 0),
          Offset(MediaQuery.of(context).size.width * 1.5, 0),
        ),
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
            align: ContentAlign.custom,
            customPosition: CustomTargetContentPosition(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
            ),
            builder: (context, controller) {
              return _TutorialCard(
                center: true,
                children: [
                  Text(
                    t.merchant_welcome_title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    t.merchant_welcome_body,
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
                        t.common_continue,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
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
            child: _TutorialCard(
              children: [
                Text(
                  t.merchant_step_enter_value_title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  t.merchant_step_enter_value_body,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
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
            child: _TutorialCard(
              padding: EdgeInsets.all(10),
              children: [
                Text(
                  t.merchant_step_add_value_title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  t.merchant_step_add_value_body,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
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
            child: _TutorialCard(
              children: [
                Text(
                  t.merchant_step_items_tab_title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  t.merchant_step_items_tab_body,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
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
            child: _TutorialCard(
              children: [
                Text(
                  t.merchant_step_create_product_title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  t.merchant_step_create_product_body,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
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
            child: _TutorialCard(
              children: [
                Text(
                  t.merchant_step_edit_delete_title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  t.merchant_step_edit_delete_body,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
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
            child: _TutorialCard(
              children: [
                Text(
                  t.merchant_step_finalize_title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  t.merchant_step_finalize_body,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
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
              return _TutorialCard(
                children: [
                  Text(
                    t.merchant_step_clear_cart_title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    t.merchant_step_clear_cart_body,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
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
          Size(MediaQuery.of(context).size.width * 0.9, 0),
          Offset(MediaQuery.of(context).size.width * 1.5, 0),
        ),
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
            align: ContentAlign.custom,
            customPosition: CustomTargetContentPosition(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
            ),
            builder: (context, controller) {
              return _TutorialCard(
                center: true,
                children: [
                  Text(
                    t.merchant_tutorial_done_title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    t.merchant_tutorial_done_body,
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
                            t.common_redo,
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
                            t.common_finish,
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
              );
            },
          ),
        ],
      ),
    );

    return targets;
  }

  void _adicionarNumero(String numero) {
    final String valorLimpo =
        valorDigitado.replaceAll('.', '').replaceAll(',', '') + numero;
    final double valor = double.parse(valorLimpo) / 100;
    if (valor > _kMaxKeypadValue) return;
    setState(() {
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

      final tutorialName =
          AppLocalizations.of(context).merchant_default_product_name;
      for (var product in products) {
        if (product.name == tutorialName && product.price == 21.00) {
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
        final looseLabel = AppLocalizations.of(context).merchant_loose_value;
        ref
            .read(cartControllerProvider.notifier)
            .updateQuantity(timestamp, looseLabel, valorAdicionado, true);
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
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).merchant_add_product_error(e.toString()),
            ),
          ),
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
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                ).merchant_update_product_error(e.toString()),
              ),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).merchant_remove_product_error(e.toString()),
            ),
          ),
        );
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
    final t = AppLocalizations.of(context);
    final keypadValue = double.tryParse(valorDigitado) ?? 0.0;
    final cartTotal = ref.read(cartTotalProvider);
    final cartItems = ref.read(cartControllerProvider.notifier).cartItems;
    final totalAmount = cartTotal + keypadValue;

    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.merchant_add_item_first),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (totalAmount < 20.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.merchant_min_sale_value),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final items = [...cartItems];
    if (keypadValue > 0) {
      items.add(
        CartItemEntity(
          productId: DateTime.now().millisecondsSinceEpoch,
          name: t.merchant_loose_value,
          price: keypadValue,
          quantity: 1,
        ),
      );
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => MerchantChargeScreen(
                  totalAmount: totalAmount,
                  items: items,
                ),
          ),
        )
        .then((_) {
          if (!mounted) return;
          setState(() {
            valorDigitado = '0.00';
          });
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
            androidTop: true,
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
                      color: context.colors.backgroundColor,
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
                          // labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[400],
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.grid_3x3),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).merchant_tab_keypad,
                                  ),
                                ],
                              ),
                            ),
                            Tab(
                              key: _itemsTabKey,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.grid_3x3),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).merchant_tab_items,
                                  ),
                                ],
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
                                        () => Center(
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
                                                AppLocalizations.of(
                                                  context,
                                                ).merchant_load_products_error,
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
                                                child: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  ).common_retry,
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
                    final keypadValue = double.tryParse(valorDigitado) ?? 0.0;
                    final effectiveAmount = cartTotal + keypadValue;
                    return FinalizarVendaButton(
                      onPressed: _finalizarVenda,
                      totalOrderAmount: effectiveAmount,
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

class _TutorialCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool center;

  const _TutorialCard({
    required this.children,
    this.padding = const EdgeInsets.all(20),
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight =
        media.size.height - media.padding.top - media.padding.bottom - 32;
    final card = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: media.size.width - 16,
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 8),
      child: center ? Center(child: card) : card,
    );
  }
}
