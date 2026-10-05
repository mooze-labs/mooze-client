import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

class FloatingLabelDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final Widget Function(T) itemIconBuilder;
  final String Function(T) itemLabelBuilder;
  final Color? borderColor;
  final Color? backgroundColor;

  const FloatingLabelDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemIconBuilder,
    required this.itemLabelBuilder,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  State<FloatingLabelDropdown<T>> createState() =>
      _FloatingLabelDropdownState<T>();
}

class _FloatingLabelDropdownState<T> extends State<FloatingLabelDropdown<T>> {
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _key = GlobalKey();

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox =
        _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder:
          (context) => GestureDetector(
            onTap: _closeDropdown,
            behavior: HitTestBehavior.translucent,
            child: Stack(
              children: [
                Positioned(
                  width: size.width,
                  child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    offset: Offset(0.0, size.height + 4.0),
                    child: GestureDetector(
                      onTap: () {},
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        color:
                            widget.backgroundColor ??
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            children:
                                widget.items.map((T item) {
                                  return InkWell(
                                    onTap: () {
                                      widget.onChanged(item);
                                      _closeDropdown();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: widget.itemIconBuilder(item),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            widget.itemLabelBuilder(item),
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBorderColor =
        widget.borderColor ?? context.colors.primaryColor;
    final resolvedBackgroundColor =
        widget.backgroundColor ?? context.colorScheme.surfaceContainerLow;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: resolvedBorderColor),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: resolvedBorderColor, width: 2),
    );

    return CompositedTransformTarget(
      link: _layerLink,
      // The key sits here so the overlay can measure the full decorated height.
      child: Container(
        key: _key,
        child: InputDecorator(
          // isFocused drives the focused border style while the dropdown is open.
          isFocused: _isOpen,
          // isEmpty: false keeps the label always floated — correct for dropdowns
          // because the field is never in an "empty unfocused" text-input state.
          isEmpty: false,
          decoration: InputDecoration(
            labelText: widget.label,
            filled: true,
            fillColor: resolvedBackgroundColor,
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          child: InkWell(
            onTap: _toggleDropdown,
            child: Row(
              children: [
                if (widget.value != null) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: widget.itemIconBuilder(widget.value as T),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.itemLabelBuilder(widget.value as T),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
                const Spacer(),
                Icon(_isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
