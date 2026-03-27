import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/shared/formatters/fiat_input_formatter.dart';
import 'package:mooze_mobile/shared/widgets.dart';

/// Add/Edit Item Modal (Presentation Layer)
///
/// A static class that provides bottom sheet modals for adding and editing products.
/// These modals are used in the merchant mode to:
/// - Create new products with name and price
/// - Edit existing products
///
/// The modal includes:
/// - Text field for product name
/// - Formatted text field for price (currency format)
/// - Cancel and Save buttons
/// - Input validation

class AddEditItemModal {
  /// Shows a bottom sheet to add a new product
  static void mostrarBottomSheetAdicionar(
    BuildContext context,
    Function(ProductEntity) onAdicionarItem, {
    String? nomePadrao,
    String? precoPadrao,
    GlobalKey? adicionarButtonKey,
  }) {
    final nomeController = TextEditingController(text: nomePadrao);
    final precoController = TextEditingController(text: precoPadrao);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => PlatformSafeArea(
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Adicionar Produto',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              size: 24,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 32),

                      Text(
                        'Nome do produto',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: nomeController,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Digite o nome do produto',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFFE91E63),
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      Text(
                        'Preço',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: precoController,
                        inputFormatters: [FiatInputFormatter()],
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'R\$ 0,00',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          prefixIcon: Container(
                            width: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'R\$',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFFE91E63),
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              text: 'Cancelar',
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            key: adicionarButtonKey,
                            child: PrimaryButton(
                              text: 'Adicionar',
                              onPressed: () {
                                if (nomeController.text.trim().isNotEmpty &&
                                    precoController.text.trim().isNotEmpty) {
                                  final preco = FiatInputFormatter.parseValue(
                                    precoController.text,
                                  );
                                  if (preco > 0) {
                                    final novoProduct = ProductEntity(
                                      name: nomeController.text.trim(),
                                      price: preco,
                                      createdAt: DateTime.now(),
                                    );
                                    onAdicionarItem(novoProduct);
                                    Navigator.pop(context);
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  /// Shows a bottom sheet to edit an existing product

  static void mostrarBottomSheetEditar(
    BuildContext context,
    ProductEntity produto,
    Function(ProductEntity) onEditarItem,
  ) {
    final nomeController = TextEditingController(text: produto.name);
    final precoController = TextEditingController(
      text: FiatInputFormatter.formatValue(produto.price),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => PlatformSafeArea(
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Editar Produto',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              size: 24,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 32),

                      Text(
                        'Nome do produto',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: nomeController,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Digite o nome do produto',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFFE91E63),
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      Text(
                        'Preço',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: precoController,
                        inputFormatters: [FiatInputFormatter()],
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'R\$ 0,00',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          prefixIcon: Container(
                            width: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'R\$',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFFE91E63),
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.outline,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFE91E63),
                                    Color(0xFFAD1457),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (nomeController.text.trim().isNotEmpty &&
                                      precoController.text.trim().isNotEmpty) {
                                    final preco = FiatInputFormatter.parseValue(
                                      precoController.text,
                                    );
                                    if (preco > 0) {
                                      final updatedProduct = ProductEntity(
                                        id: produto.id,
                                        name: nomeController.text.trim(),
                                        price: preco,
                                        createdAt: produto.createdAt,
                                      );
                                      onEditarItem(updatedProduct);
                                      Navigator.pop(context);
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: Text(
                                  'Salvar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
