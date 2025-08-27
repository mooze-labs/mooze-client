import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class FilterOrderBy extends StatefulWidget {
  final bool isMostRecentSelected;
  final ValueChanged<bool> onSelectionChanged;

  const FilterOrderBy({
    Key? key,
    required this.isMostRecentSelected,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  State<FilterOrderBy> createState() => _FilterOrderByState();
}

class _FilterOrderByState extends State<FilterOrderBy> {
  late bool _isMostRecentSelected;

  @override
  void initState() {
    super.initState();
    _isMostRecentSelected = widget.isMostRecentSelected;
  }

  void _updateSelection(bool isMostRecent) {
    setState(() {
      _isMostRecentSelected = isMostRecent;
    });
    widget.onSelectionChanged(_isMostRecentSelected);
  }

  @override
  Widget build(BuildContext context) {
    const double totalSpacing = 2 * 30;
    final double itemWidth =
        (MediaQuery.of(context).size.width - totalSpacing) / 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            _updateSelection(true);
          },
          child: Container(
            width: itemWidth,
            height: 47,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color:
                  _isMostRecentSelected
                      ? AppColors.primaryColor.withOpacity(0.3)
                      : Colors.grey,
              border:
                  _isMostRecentSelected
                      ? Border.all(color: AppColors.primaryColor, width: 2)
                      : null,
            ),

            child: Center(
              child: Text(
                'Mais Recente',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            _updateSelection(!_isMostRecentSelected);
          },
          child: Container(
            width: itemWidth,
            height: 47,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.navBarFabBackground],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.compare_arrows_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            _updateSelection(false);
          },
          child: Container(
            width: itemWidth,
            height: 47,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color:
                  !_isMostRecentSelected
                      ? AppColors.primaryColor.withOpacity(0.3)
                      : Colors.grey,
              border:
                  !_isMostRecentSelected
                      ? Border.all(color: AppColors.primaryColor, width: 2)
                      : null,
            ),
            child: Center(
              child: Text(
                'Mais Antigo',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
