import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/formatters/fiat_input_formatter.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Add/Edit Item Modal (Presentation Layer)
///
/// Opens the product form of Merchant Mode in a floating glass sheet:
/// - Create new products with name and price
/// - Edit existing products
///
/// Both use the same form: a name field, a price field in reais, and one
/// main button. The form checks the fields when the merchant taps the
/// button and says what to fix below each field. The messages then update
/// while the merchant types.
class AddEditItemModal {
  /// Shows a bottom sheet to add a new product
  static void mostrarBottomSheetAdicionar(
    BuildContext context,
    Function(ProductEntity) onAdicionarItem, {
    String? nomePadrao,
    String? precoPadrao,
    GlobalKey? adicionarButtonKey,
  }) {
    showFloatingGlassSheet<void>(
      context,
      builder: (_) => _ProductFormSheet(
        isEdit: false,
        initialName: nomePadrao,
        initialPrice: precoPadrao,
        submitKey: adicionarButtonKey,
        onSubmit: (name, price) => onAdicionarItem(
          ProductEntity(name: name, price: price, createdAt: DateTime.now()),
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
    showFloatingGlassSheet<void>(
      context,
      builder: (_) => _ProductFormSheet(
        isEdit: true,
        initialName: produto.name,
        initialPrice: FiatInputFormatter.formatValue(produto.price),
        onSubmit: (name, price) => onEditarItem(
          ProductEntity(
            id: produto.id,
            name: name,
            price: price,
            createdAt: produto.createdAt,
          ),
        ),
      ),
    );
  }
}

/// The product form inside the floating glass sheet.
class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({
    required this.isEdit,
    required this.onSubmit,
    this.initialName,
    this.initialPrice,
    this.submitKey,
  });

  final bool isEdit;
  final String? initialName;
  final String? initialPrice;

  /// Key of the main button, for the Merchant Mode tutorial.
  final GlobalKey? submitKey;

  /// Receives the trimmed name and a price above zero.
  final void Function(String name, double price) onSubmit;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _priceController = TextEditingController(
    text: widget.initialPrice,
  );
  final _priceFocus = FocusNode();

  /// True after the first tap on the main button. The fields show their
  /// messages from then on.
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  String get _name => _nameController.text.trim();

  double get _price {
    final text = _priceController.text.trim();
    return text.isEmpty ? 0 : FiatInputFormatter.parseValue(text);
  }

  void _onChanged(String _) {
    if (_submitted) setState(() {});
  }

  void _submit() {
    setState(() => _submitted = true);
    if (_name.isEmpty || _price <= 0) return;
    widget.onSubmit(_name, _price);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;

    return Padding(
      // The sheet rises with the keyboard.
      padding: EdgeInsets.only(bottom: keyboard),
      child: GlassSheet(
        constraints: BoxConstraints(
          maxHeight: media.size.height - keyboard - media.padding.top - 24,
        ),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassSheetHeader(
              title: widget.isEdit
                  ? t.merchant_edit_product_title
                  : t.merchant_add_product_title,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FormField(
                      label: t.merchant_product_name_label,
                      controller: _nameController,
                      hintText: t.merchant_product_name_hint,
                      errorText: _submitted && _name.isEmpty
                          ? t.merchant_product_name_required
                          : null,
                      autofocus: !widget.isEdit,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      onChanged: _onChanged,
                      onSubmitted: (_) => _priceFocus.requestFocus(),
                    ),
                    const SizedBox(height: 20),
                    _FormField(
                      label: t.merchant_price_label,
                      controller: _priceController,
                      focusNode: _priceFocus,
                      hintText: '0,00',
                      prefix: r'R$',
                      errorText: _submitted && _price <= 0
                          ? t.merchant_product_price_required
                          : null,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [FiatInputFormatter()],
                      textInputAction: TextInputAction.done,
                      onChanged: _onChanged,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      key: widget.submitKey,
                      text: widget.isEdit
                          ? t.common_save
                          : t.merchant_add_action,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labeled field on a glass well.
///
/// The well has a hairline at rest, a brand rim with the focus, and the
/// negative color with a message below when the value is not valid.
class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    this.focusNode,
    this.hintText,
    this.prefix,
    this.errorText,
    this.autofocus = false,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final FocusNode? focusNode;
  final String? hintText;

  /// Text before the value, such as the currency symbol.
  final String? prefix;
  final String? errorText;
  final bool autofocus;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(14));
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );
    final negative = context.colors.negativeColor;
    final hairline = AppSurfaces.hairline(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.textPrimary,
            fontFeatures: prefix == null
                ? null
                : const [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textTertiary,
            ),
            errorText: errorText,
            errorStyle: context.textTheme.bodySmall?.copyWith(color: negative),
            errorMaxLines: 2,
            filled: true,
            fillColor: GlassStyle.of(context).lensFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: prefix == null
                ? null
                : Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 16,
                      end: 8,
                    ),
                    child: Text(
                      prefix!,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
            prefixIconConstraints: const BoxConstraints(),
            border: outline(hairline),
            enabledBorder: outline(hairline),
            focusedBorder: outline(context.colors.primaryColor, 1.5),
            errorBorder: outline(negative),
            focusedErrorBorder: outline(negative, 1.5),
          ),
        ),
      ],
    );
  }
}
