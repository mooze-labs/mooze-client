import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class FloatingLabelDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final Widget Function(T) itemIconBuilder;
  final String Function(T) itemLabelBuilder;
  final Color borderColor;
  final Color backgroundColor;

  const FloatingLabelDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemIconBuilder,
    required this.itemLabelBuilder,
    this.borderColor = AppColors.primaryColor,
    this.backgroundColor = AppColors.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(top: 8),
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: Container(),
            dropdownColor: Color(0xFF2A2A2A),
            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
            items:
                items.map((T item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: itemIconBuilder(item),
                        ),
                        SizedBox(width: 12),
                        Text(
                          itemLabelBuilder(item),
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            onChanged: onChanged,
          ),
        ),
        Positioned(
          left: 12,
          top: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4),
            color: backgroundColor,
            child: Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
