class TransactionFiltersEntity {
  final String? sort;
  final Map<String, dynamic>? filter;
  final bool? orderByMostRecent;
  final DateTime? startDate;
  final DateTime? endDate;

  TransactionFiltersEntity({
    this.sort,
    this.filter,
    this.orderByMostRecent,
    this.startDate,
    this.endDate,
  });

  TransactionFiltersEntity copyWith({
    String? sort,
    Map<String, dynamic>? filter,
    bool? orderByMostRecent,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TransactionFiltersEntity(
      sort: sort ?? this.sort,
      filter: filter ?? this.filter,
      orderByMostRecent: orderByMostRecent ?? this.orderByMostRecent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class TransactionFilterDto extends TransactionFiltersEntity {
  TransactionFilterDto({
    super.sort,
    super.filter,
    super.orderByMostRecent,
    super.startDate,
    super.endDate,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {};
    if (sort != null) {
      data['sort'] = sort;
    }
    if (filter != null && filter!.isNotEmpty) {
      data['filter'] = filter;
    }
    if (orderByMostRecent != null) {
      data['orderByMostRecent'] = orderByMostRecent;
    }
    if (startDate != null) {
      data['startDate'] = startDate!.millisecondsSinceEpoch;
    }
    if (endDate != null) {
      data['endDate'] = endDate!.millisecondsSinceEpoch;
    }
    return data;
  }

  factory TransactionFilterDto.fromMap(Map<String, dynamic> map) {
    return TransactionFilterDto(
      sort: map['sort'],
      filter:
          map['filter'] != null
              ? Map<String, dynamic>.from(map['filter'])
              : null,
      orderByMostRecent: map['orderByMostRecent'],
      startDate:
          map['startDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['startDate'])
              : null,
      endDate:
          map['endDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
              : null,
    );
  }

  factory TransactionFilterDto.fromJson(Map<String, dynamic> json) {
    return TransactionFilterDto(
      sort: json['sort'],
      filter:
          json['filter'] != null
              ? Map<String, dynamic>.from(json['filter'])
              : null,
      orderByMostRecent: json['orderByMostRecent'],
      startDate:
          json['startDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['startDate'])
              : null,
      endDate:
          json['endDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['endDate'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sort': sort,
      'filter': filter,
      'orderByMostRecent': orderByMostRecent,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
    };
  }
}

class AssetEntity {
  final String id;
  final String name;
  final String iconPath;

  AssetEntity({required this.id, required this.name, required this.iconPath});
}

enum TransactionTypeEntity { all, send, receive, swap }

enum TransactionStatusEntity { all, pending, confirmed, failed, refundable }
