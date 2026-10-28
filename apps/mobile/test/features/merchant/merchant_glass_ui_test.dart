import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/cart_item_entity.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/merchant/domain/repositories/merchant_mode_repository.dart';
import 'package:mooze_mobile/features/merchant/presentation/controllers/controllers.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_mode_exit_screen.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_mode_screen.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/add_edit_item_modal.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/finalizar_venda_button.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/items_list_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/keypad_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_header_widget.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_segmented_tabs.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/utils/result.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/test_app.dart';
import '../../shared/widgets/motion/motion_test_helpers.dart';

final _createdAt = DateTime(2026, 10, 28);

final _products = [
  ProductEntity(id: 1, name: 'Café coado', price: 6.5, createdAt: _createdAt),
  ProductEntity(id: 2, name: 'Pão de queijo', price: 4, createdAt: _createdAt),
];

/// Gives the test a phone screen, so the whole screen is built.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(393 * 3, 852 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// A screen with one button that runs [open].
Widget _launcher(void Function(BuildContext context) open) => wrapForTest(
  Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => open(context),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

/// Runs the custom screen reader action [label] on [node].
void _performCustomAction(SemanticsNode node, String label) {
  node.owner!.performAction(
    node.id,
    SemanticsAction.customAction,
    CustomSemanticsAction.getIdentifier(CustomSemanticsAction(label: label)),
  );
}

void main() {
  group('keypad', () {
    testWidgets('types digits, labels its icon keys, and blocks an empty add', (
      tester,
    ) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      final digits = <String>[];
      var deletes = 0;
      var adds = 0;
      Future<void> pump(String typed) => tester.pumpWidget(
        wrapForTest(
          Scaffold(
            body: KeypadWidget(
              typedValue: typed,
              onAddDigit: digits.add,
              onDeleteDigit: () => deletes++,
              onAddToTotal: () => adds++,
            ),
          ),
        ),
      );

      await pump('0.00');
      await tester.tap(find.text('7'));
      expect(digits, ['7']);

      // The add key does nothing while the typed value is zero.
      await tester.tap(find.bySemanticsLabel('Adicionar valor'));
      expect(adds, 0);

      final delete = MaterialLocalizations.of(
        tester.element(find.byType(KeypadWidget)),
      ).deleteButtonTooltip;
      await tester.tap(find.bySemanticsLabel(delete));
      expect(deletes, 1);

      await pump('45.90');
      // The value uses the Brazilian format.
      expect(find.text('45,90'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Adicionar valor'));
      expect(adds, 1);
      handle.dispose();
    });

    testWidgets('scrolls instead of overflowing on a short screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        wrapForTest(
          Scaffold(
            body: SizedBox(
              height: 300,
              child: KeypadWidget(
                typedValue: '0.00',
                onAddDigit: (_) {},
                onDeleteDigit: () {},
                onAddToTotal: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('segmented tabs', () {
    Future<TabController> pumpTabs(WidgetTester tester) async {
      final controller = TabController(length: 2, vsync: const TestVSync());
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wrapForTest(
          Scaffold(
            body: MerchantSegmentedTabs(
              controller: controller,
              segments: const [
                MerchantSegment(icon: Icons.dialpad_rounded, label: 'Teclado'),
                MerchantSegment(
                  icon: Icons.inventory_2_outlined,
                  label: 'Itens',
                ),
              ],
            ),
          ),
        ),
      );
      return controller;
    }

    testWidgets('a tap changes the tab and marks the selection', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = await pumpTabs(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Teclado')),
        isSemantics(isSelected: true, isButton: true),
      );

      await tester.tap(find.text('Itens'));
      await tester.pumpAndSettle();

      expect(controller.index, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Itens')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Teclado')),
        isSemantics(isSelected: false),
      );
      handle.dispose();
    });

    testWidgets('with reduced motion, the lens moves at once', (tester) async {
      reduceMotion(tester);
      final controller = await pumpTabs(tester);

      await tester.tap(find.text('Itens'));
      await tester.pump();

      expect(controller.index, 1);
      expect(controller.animation!.value, 1);
    });
  });

  group('items list', () {
    Widget items({
      List<ProductEntity>? products,
      Map<int, CartItemEntity> cart = const {},
      void Function(int)? onEdit,
      void Function(int)? onRemove,
      void Function(int, bool)? onQuantity,
      VoidCallback? onAdd,
    }) => wrapForTest(
      Scaffold(
        body: ItemsListWidget(
          products: products ?? _products,
          cart: cart,
          onEditItem: onEdit ?? (_) {},
          onRemoveItem: onRemove ?? (_) {},
          onUpdateQuantity: onQuantity ?? (_, _) {},
          onAddItem: onAdd ?? () {},
        ),
      ),
    );

    testWidgets('rows show the price and step the quantity', (tester) async {
      final changes = <(int, bool)>[];
      await tester.pumpWidget(
        items(onQuantity: (index, increase) => changes.add((index, increase))),
      );

      expect(find.textContaining('6,50'), findsOneWidget);
      expect(find.textContaining('4,00'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_rounded).at(1));
      // The minus of a product that is not in the cart does nothing.
      await tester.tap(find.byIcon(Icons.remove_rounded).at(1));

      expect(changes, [(1, true)]);
    });

    testWidgets('screen readers adjust the quantity and edit or delete', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final changes = <(int, bool)>[];
      final edited = <int>[];
      final removed = <int>[];
      await tester.pumpWidget(
        items(
          cart: const {
            1: CartItemEntity(
              productId: 1,
              name: 'Café coado',
              price: 6.5,
              quantity: 2,
            ),
          },
          onQuantity: (index, increase) => changes.add((index, increase)),
          onEdit: edited.add,
          onRemove: removed.add,
        ),
      );

      final finder = find.bySemanticsLabel(RegExp('^Café coado'));
      final node = tester.getSemantics(finder);
      expect(node.value, 'x2');
      expect(
        node,
        isSemantics(
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          customActions: [
            const CustomSemanticsAction(label: 'Editar'),
            const CustomSemanticsAction(label: 'Deletar'),
          ],
        ),
      );

      node.owner!.performAction(node.id, SemanticsAction.decrease);
      _performCustomAction(node, 'Editar');
      expect(changes, [(0, false)]);
      expect(edited, [0]);

      // Delete asks first.
      _performCustomAction(node, 'Deletar');
      await tester.pumpAndSettle();
      expect(find.text('Deletar item'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Deletar'));
      await tester.pumpAndSettle();
      expect(removed, [0]);
      handle.dispose();
    });

    testWidgets('an empty list explains itself and keeps the add button', (
      tester,
    ) async {
      var adds = 0;
      await tester.pumpWidget(items(products: const [], onAdd: () => adds++));

      expect(find.text('Nenhum produto cadastrado'), findsOneWidget);
      await tester.tap(find.text('Adicionar Produto'));
      expect(adds, 1);
    });
  });

  group('product form', () {
    testWidgets('explains empty fields and saves a valid product', (
      tester,
    ) async {
      _phone(tester);
      ProductEntity? saved;
      await tester.pumpWidget(
        _launcher(
          (context) => AddEditItemModal.mostrarBottomSheetAdicionar(
            context,
            (product) => saved = product,
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adicionar'));
      await tester.pump();
      expect(find.text('Informe o nome do produto.'), findsOneWidget);
      expect(find.text('Informe um preço maior que zero.'), findsOneWidget);
      expect(saved, isNull);

      await tester.enterText(find.byType(TextField).first, '  Café  ');
      await tester.enterText(find.byType(TextField).last, '650');
      await tester.pump();
      // The messages update while the merchant types.
      expect(find.text('Informe o nome do produto.'), findsNothing);
      expect(find.text('Informe um preço maior que zero.'), findsNothing);

      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();
      expect(saved?.name, 'Café');
      expect(saved?.price, 6.5);
      expect(find.byType(GlassSheet), findsNothing);
    });

    testWidgets('edits a product and keeps its id and date', (tester) async {
      _phone(tester);
      ProductEntity? edited;
      await tester.pumpWidget(
        _launcher(
          (context) => AddEditItemModal.mostrarBottomSheetEditar(
            context,
            ProductEntity(id: 7, name: 'Suco', price: 9, createdAt: _createdAt),
            (product) => edited = product,
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Produto'), findsOneWidget);
      expect(find.text('9,00'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Suco de uva');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(edited?.id, 7);
      expect(edited?.name, 'Suco de uva');
      expect(edited?.price, 9);
      expect(edited?.createdAt, _createdAt);
    });
  });

  group('header and main button', () {
    testWidgets('the header shows the total and offers clear only with items', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Future<void> pump(double total) => tester.pumpWidget(
        wrapForTest(
          Scaffold(
            body: MerchantHeaderWidget(
              totalAmountInBRL: total,
              onClearCart: () {},
            ),
          ),
        ),
      );

      await pump(0);
      expect(find.text('Limpar'), findsNothing);

      await pump(17);
      await tester.pumpAndSettle();
      expect(find.text('Limpar'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Total da venda, R\$.17,00$')),
        findsOneWidget,
      );
      // The amount animation waits one interval between two changes.
      await tester.pump(const Duration(seconds: 1));
      handle.dispose();
    });

    testWidgets('the main button explains the minimum sale', (tester) async {
      var presses = 0;
      Future<void> pump(double total) => tester.pumpWidget(
        wrapForTest(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: FinalizarVendaButton(
                onPressed: () => presses++,
                totalOrderAmount: total,
              ),
            ),
          ),
        ),
      );

      await pump(15);
      await tester.pumpAndSettle();
      expect(find.text('Mínimo R\$ 20,00'), findsOneWidget);
      await tester.tap(find.text('Finalizar Venda'));
      expect(presses, 0);

      await pump(25);
      await tester.pumpAndSettle();
      expect(find.text('Mínimo R\$ 20,00'), findsNothing);
      await tester.tap(find.text('Finalizar Venda'));
      expect(presses, 1);
    });
  });

  group('merchant mode screen', () {
    testWidgets('clearing the cart asks for a confirmation', (tester) async {
      _phone(tester);
      SharedPreferences.setMockInitialValues({'merchant_tutorial_shown': true});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            merchantModeRepositoryProvider.overrideWithValue(_Repository()),
            productControllerProvider.overrideWith(_Products.new),
          ],
          child: wrapForTest(const MerchantModeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MerchantModeScreen)),
      );
      container
          .read(cartControllerProvider.notifier)
          .updateQuantity(1, 'Café coado', 6.5, true);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();
      expect(find.text('Limpar carrinho?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(container.read(cartControllerProvider), isNotEmpty);

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Limpar'));
      await tester.pumpAndSettle();
      expect(container.read(cartControllerProvider), isEmpty);
      // The total animation waits one interval between two changes.
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('exit screen', () {
    Finder questionFade() => find
        .ancestor(
          of: find.text('Pronto para vender?'),
          matching: find.byType(FadeTransition),
        )
        .first;

    Future<void> pumpExit(WidgetTester tester) async {
      _phone(tester);
      await tester.pumpWidget(
        ProviderScope(child: wrapForTest(const MerchantModeExitScreen())),
      );
    }

    testWidgets('the content fades in', (tester) async {
      await pumpExit(tester);
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        tester.widget<FadeTransition>(questionFade()).opacity.value,
        lessThan(1),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FadeTransition>(questionFade()).opacity.value, 1);
    });

    testWidgets('with reduced motion, the content shows at once', (
      tester,
    ) async {
      reduceMotion(tester);
      await pumpExit(tester);
      await tester.pump();
      expect(tester.widget<FadeTransition>(questionFade()).opacity.value, 1);
    });
  });

  test('the limit message uses the Brazilian format', () {
    final t = lookupAppLocalizations(const Locale('pt'));
    const validation = MerchantValidation.failure(
      MerchantValidationError.aboveTransaction,
      1250,
    );
    expect(
      validation.localizedMessage(t),
      'Limite por transação: R\$ 1.250,00',
    );
  });
}

class _Repository implements MerchantModeRepository {
  @override
  Future<Result<bool>> isMerchantModeActive() async => Success(true);

  @override
  Future<Result<void>> setMerchantModeActive(
    bool active, {
    String origin = '/home',
  }) async => Success(null);

  @override
  Future<Result<String>> getMerchantModeOrigin() async => Success('/home');

  @override
  Future<Result<void>> clearMerchantMode() async => Success(null);
}

class _Products extends ProductController {
  @override
  Future<List<ProductEntity>> build() async => _products;
}
