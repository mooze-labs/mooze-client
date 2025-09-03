import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';

class PixFiltersEntity {
  final Map<String, dynamic>? filter;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? orderByMostRecent;

  PixFiltersEntity({
    this.filter,
    this.startDate,
    this.endDate,
    this.orderByMostRecent,
  });

  PixFiltersEntity copyWith({
    Map<String, dynamic>? filter,
    DateTime? startDate,
    DateTime? endDate,
    bool? orderByMostRecent,
  }) {
    return PixFiltersEntity(
      filter: filter ?? this.filter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      orderByMostRecent: orderByMostRecent ?? this.orderByMostRecent,
    );
  }
}

class AssetEntity {
  final String id;
  final String name;
  final String iconPath;

  AssetEntity({required this.id, required this.name, required this.iconPath});
}

extension PixDepositFilters on List<PixDeposit> {
  List<PixDeposit> applyFilters(PixFiltersEntity filters) {
    List<PixDeposit> filtered = List.from(this);

    final status = filters.filter?['status'] as String?;
    if (status != null && status != 'all') {
      filtered =
          filtered.where((deposit) => deposit.status.name == status).toList();
    }

    final assetIds = filters.filter?['assets'] as List<String>?;
    if (assetIds != null && assetIds.isNotEmpty) {
      filtered =
          filtered
              .where((deposit) => assetIds.contains(deposit.asset.id))
              .toList();
    }

    if (filters.startDate != null) {
      filtered =
          filtered
              .where(
                (deposit) =>
                    deposit.createdAt.isAfter(filters.startDate!) ||
                    deposit.createdAt.isAtSameMomentAs(filters.startDate!),
              )
              .toList();
    }

    if (filters.endDate != null) {
      final endOfDay = DateTime(
        filters.endDate!.year,
        filters.endDate!.month,
        filters.endDate!.day,
        23,
        59,
        59,
        999,
      );
      filtered =
          filtered
              .where(
                (deposit) =>
                    deposit.createdAt.isBefore(endOfDay) ||
                    deposit.createdAt.isAtSameMomentAs(endOfDay),
              )
              .toList();
    }

    final orderByMostRecent = filters.orderByMostRecent ?? true;
    filtered.sort((a, b) {
      if (orderByMostRecent) {
        return b.createdAt.compareTo(a.createdAt);
      } else {
        return a.createdAt.compareTo(b.createdAt);
      }
    });

    return filtered;
  }
}
