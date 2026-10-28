import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/utils/error_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/cart_item_entity.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/merchant/presentation/controllers/controllers.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_charge_screen.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/add_edit_item_modal.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/items_list_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/keypad_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_confirm_dialog.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_glass_button.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_header_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_segmented_tabs.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/finalizar_venda_button.dart';
import 'package:mooze_mobile/features/merchant/presentation/services/merchant_tutorial_service.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Merchant Mode Screen (Presentation Layer)
///
/// The main screen for merchant mode - allows businesses to create charges
/// and accept payments from customers.
///
/// The screen is a small point of sale on the app backdrop: a glass header
/// with the sale total as the hero, a glass switch between the keypad and
/// the product list, and the "Finish sale" button pinned at the bottom.
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

    final t = AppLocalizations.of(context);
    final focusDuration = Motion.of(context, Motion.durationSlow);
    _tutorialCoachMark = TutorialCoachMark(
      targets: _createTutorialTargets(),
      // A neutral scrim, so the glass cards and the brand button read as
      // on the rest of the app.
      colorShadow: context.colorScheme.scrim,
      opacityShadow: 0.8,
      paddingFocus: 10,
      focusAnimationDuration: focusDuration,
      unFocusAnimationDuration: focusDuration,
      pulseEnable: !Motion.isReduced(context),
      alignSkip: Alignment.topRight,
      skipWidget: _TutorialSkip(label: t.merchant_tutorial_skip),
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

  /// A step that points at the widget of [key], with a glass card that
  /// explains it.
  TargetFocus _stepTarget({
    required String identify,
    required GlobalKey key,
    required ShapeLightFocus shape,
    required ContentAlign align,
    required String title,
    required String body,
    double? radius,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: key,
      shape: shape,
      radius: radius,
      contents: [
        TargetContent(
          align: align,
          child: _TutorialCard(title: title, body: body),
        ),
      ],
    );
  }

  /// A step without a target, with a card in the middle of the screen.
  TargetFocus _centeredTarget({
    required String identify,
    required Widget Function(BuildContext, TutorialCoachMarkController) builder,
  }) {
    return TargetFocus(
      identify: identify,
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
          builder: builder,
        ),
      ],
    );
  }

  List<TargetFocus> _createTutorialTargets() {
    final t = AppLocalizations.of(context);
    return [
      _centeredTarget(
        identify: "welcome",
        builder: (context, controller) => _TutorialCard(
          center: true,
          title: t.merchant_welcome_title,
          body: t.merchant_welcome_body,
          actions: PrimaryButton(
            text: t.common_continue,
            onPressed: () => controller.next(),
          ),
        ),
      ),
      _stepTarget(
        identify: "valor_input",
        key: _valorInputKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        align: ContentAlign.bottom,
        title: t.merchant_step_enter_value_title,
        body: t.merchant_step_enter_value_body,
      ),
      _stepTarget(
        identify: "add_button",
        key: _addButtonKey,
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.top,
        title: t.merchant_step_add_value_title,
        body: t.merchant_step_add_value_body,
      ),
      _stepTarget(
        identify: "items_tab",
        key: _itemsTabKey,
        shape: ShapeLightFocus.RRect,
        radius: 24,
        align: ContentAlign.bottom,
        title: t.merchant_step_items_tab_title,
        body: t.merchant_step_items_tab_body,
      ),
      _stepTarget(
        identify: "add_product",
        key: _addProductButtonKey,
        // The add button is a capsule.
        shape: ShapeLightFocus.RRect,
        radius: 28,
        align: ContentAlign.top,
        title: t.merchant_step_create_product_title,
        body: t.merchant_step_create_product_body,
      ),
      _stepTarget(
        identify: "manage_products",
        key: _firstProductKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        align: ContentAlign.bottom,
        title: t.merchant_step_edit_delete_title,
        body: t.merchant_step_edit_delete_body,
      ),
      _stepTarget(
        identify: "finalizar_venda",
        key: _finalizarVendaKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        align: ContentAlign.top,
        title: t.merchant_step_finalize_title,
        body: t.merchant_step_finalize_body,
      ),
      _stepTarget(
        identify: "limpar",
        key: _limparKey,
        shape: ShapeLightFocus.RRect,
        radius: 24,
        align: ContentAlign.bottom,
        title: t.merchant_step_clear_cart_title,
        body: t.merchant_step_clear_cart_body,
      ),
      _centeredTarget(
        identify: "conclusion",
        builder: (context, controller) => _TutorialCard(
          center: true,
          title: t.merchant_tutorial_done_title,
          body: t.merchant_tutorial_done_body,
          actions: Row(
            children: [
              Expanded(
                child: MerchantGlassButton(
                  label: t.common_redo,
                  onPressed: () async {
                    controller.skip();
                    await _limparDadosTutorial();
                    await _tutorialService.resetTutorial();
                    if (mounted) {
                      _showTutorial();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: t.common_finish,
                  onPressed: () async {
                    await _limparDadosTutorial();
                    controller.next();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ];
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

      final tutorialName = AppLocalizations.of(
        context,
      ).merchant_default_product_name;
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
        AppSnackBar.error(
          context,
          AppLocalizations.of(
            context,
          ).merchant_add_product_error(humanizeError(context, e)),
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
          AppSnackBar.error(
            context,
            AppLocalizations.of(
              context,
            ).merchant_update_product_error(humanizeError(context, e)),
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
        AppSnackBar.error(
          context,
          AppLocalizations.of(
            context,
          ).merchant_remove_product_error(humanizeError(context, e)),
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
      AppSnackBar.warning(context, t.merchant_add_item_first);
      return;
    }

    if (totalAmount < 20.0) {
      AppSnackBar.error(context, t.merchant_min_sale_value);
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
            builder: (context) =>
                MerchantChargeScreen(totalAmount: totalAmount, items: items),
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

  /// Asks before the cart is cleared. The cart holds the whole sale, so a
  /// stray tap must not lose it.
  Future<void> _confirmClearCart() async {
    final t = AppLocalizations.of(context);
    final confirmed = await showMerchantConfirmDialog(
      context,
      title: t.merchant_clear_cart_confirm_title,
      message: t.merchant_clear_cart_confirm_body,
      confirmLabel: t.merchant_clear_cart,
    );
    if (confirmed && mounted) _limparValor();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleWillPop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: AppBackdrop()),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final valorReais = ref.watch(cartTotalProvider);
                        return Container(
                          key: _headerKey,
                          child: MerchantHeaderWidget(
                            totalAmountInBRL: valorReais,
                            onClearCart: _confirmClearCart,
                            onBack: _handleWillPop,
                            clearButtonKey: _limparKey,
                            totalAmountKey: _valorTotalKey,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: MerchantSegmentedTabs(
                      controller: _tabController,
                      segments: [
                        MerchantSegment(
                          icon: Icons.dialpad_rounded,
                          label: t.merchant_tab_keypad,
                        ),
                        MerchantSegment(
                          key: _itemsTabKey,
                          icon: Icons.inventory_2_outlined,
                          label: t.merchant_tab_items,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
                                      onUpdateQuantity: _atualizarQuantidade,
                                      onAddItem: _mostrarBottomSheetAdicionar,
                                      addButtonKey: _addProductButtonKey,
                                      firstItemKey: _firstProductKey,
                                    );
                                  },
                                );
                              },
                              loading: () => const ItemsListSkeleton(),
                              error: (error, stackTrace) => ItemsListError(
                                details: humanizeError(context, error),
                                onRetry: () {
                                  ref.invalidate(productControllerProvider);
                                },
                              ),
                            );
                          },
                        ),
                      ],
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
          ],
        ),
      ),
    );
  }
}

/// A tutorial card: an opaque glass panel with a title, a text, and
/// optional actions.
///
/// The card never grows past the screen. On a short screen, or with very
/// large text, it scales down to fit.
class _TutorialCard extends StatelessWidget {
  final String title;
  final String body;
  final Widget? actions;
  final bool center;

  const _TutorialCard({
    required this.title,
    required this.body,
    this.actions,
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
          child: LiquidGlass(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            blurBackdrop: false,
            opaque: true,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: context.textTheme.titleLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  if (actions != null) ...[
                    const SizedBox(height: 20),
                    actions!,
                  ],
                ],
              ),
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

/// The skip control of the tutorial: a glass pill with a translated label.
class _TutorialSkip extends StatelessWidget {
  const _TutorialSkip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LiquidGlass(
        blurBackdrop: false,
        opaque: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
