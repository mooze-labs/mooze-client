// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class Swaps extends Table with TableInfo<Swaps, SwapsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Swaps(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  late final GeneratedColumn<String> sendAsset = GeneratedColumn<String>(
    'send_asset',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 64,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> receiveAsset = GeneratedColumn<String>(
    'receive_asset',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 64,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> sendAmount = GeneratedColumn<int>(
    'send_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> receiveAmount = GeneratedColumn<int>(
    'receive_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression(
      'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sendAsset,
    receiveAsset,
    sendAmount,
    receiveAmount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'swaps';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SwapsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SwapsData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      sendAsset:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}send_asset'],
          )!,
      receiveAsset:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}receive_asset'],
          )!,
      sendAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}send_amount'],
          )!,
      receiveAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}receive_amount'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  Swaps createAlias(String alias) {
    return Swaps(attachedDatabase, alias);
  }
}

class SwapsData extends DataClass implements Insertable<SwapsData> {
  final int id;
  final String sendAsset;
  final String receiveAsset;
  final int sendAmount;
  final int receiveAmount;
  final DateTime createdAt;
  const SwapsData({
    required this.id,
    required this.sendAsset,
    required this.receiveAsset,
    required this.sendAmount,
    required this.receiveAmount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['send_asset'] = Variable<String>(sendAsset);
    map['receive_asset'] = Variable<String>(receiveAsset);
    map['send_amount'] = Variable<int>(sendAmount);
    map['receive_amount'] = Variable<int>(receiveAmount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SwapsCompanion toCompanion(bool nullToAbsent) {
    return SwapsCompanion(
      id: Value(id),
      sendAsset: Value(sendAsset),
      receiveAsset: Value(receiveAsset),
      sendAmount: Value(sendAmount),
      receiveAmount: Value(receiveAmount),
      createdAt: Value(createdAt),
    );
  }

  factory SwapsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SwapsData(
      id: serializer.fromJson<int>(json['id']),
      sendAsset: serializer.fromJson<String>(json['sendAsset']),
      receiveAsset: serializer.fromJson<String>(json['receiveAsset']),
      sendAmount: serializer.fromJson<int>(json['sendAmount']),
      receiveAmount: serializer.fromJson<int>(json['receiveAmount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sendAsset': serializer.toJson<String>(sendAsset),
      'receiveAsset': serializer.toJson<String>(receiveAsset),
      'sendAmount': serializer.toJson<int>(sendAmount),
      'receiveAmount': serializer.toJson<int>(receiveAmount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SwapsData copyWith({
    int? id,
    String? sendAsset,
    String? receiveAsset,
    int? sendAmount,
    int? receiveAmount,
    DateTime? createdAt,
  }) => SwapsData(
    id: id ?? this.id,
    sendAsset: sendAsset ?? this.sendAsset,
    receiveAsset: receiveAsset ?? this.receiveAsset,
    sendAmount: sendAmount ?? this.sendAmount,
    receiveAmount: receiveAmount ?? this.receiveAmount,
    createdAt: createdAt ?? this.createdAt,
  );
  SwapsData copyWithCompanion(SwapsCompanion data) {
    return SwapsData(
      id: data.id.present ? data.id.value : this.id,
      sendAsset: data.sendAsset.present ? data.sendAsset.value : this.sendAsset,
      receiveAsset:
          data.receiveAsset.present
              ? data.receiveAsset.value
              : this.receiveAsset,
      sendAmount:
          data.sendAmount.present ? data.sendAmount.value : this.sendAmount,
      receiveAmount:
          data.receiveAmount.present
              ? data.receiveAmount.value
              : this.receiveAmount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SwapsData(')
          ..write('id: $id, ')
          ..write('sendAsset: $sendAsset, ')
          ..write('receiveAsset: $receiveAsset, ')
          ..write('sendAmount: $sendAmount, ')
          ..write('receiveAmount: $receiveAmount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sendAsset,
    receiveAsset,
    sendAmount,
    receiveAmount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SwapsData &&
          other.id == this.id &&
          other.sendAsset == this.sendAsset &&
          other.receiveAsset == this.receiveAsset &&
          other.sendAmount == this.sendAmount &&
          other.receiveAmount == this.receiveAmount &&
          other.createdAt == this.createdAt);
}

class SwapsCompanion extends UpdateCompanion<SwapsData> {
  final Value<int> id;
  final Value<String> sendAsset;
  final Value<String> receiveAsset;
  final Value<int> sendAmount;
  final Value<int> receiveAmount;
  final Value<DateTime> createdAt;
  const SwapsCompanion({
    this.id = const Value.absent(),
    this.sendAsset = const Value.absent(),
    this.receiveAsset = const Value.absent(),
    this.sendAmount = const Value.absent(),
    this.receiveAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SwapsCompanion.insert({
    this.id = const Value.absent(),
    required String sendAsset,
    required String receiveAsset,
    required int sendAmount,
    required int receiveAmount,
    this.createdAt = const Value.absent(),
  }) : sendAsset = Value(sendAsset),
       receiveAsset = Value(receiveAsset),
       sendAmount = Value(sendAmount),
       receiveAmount = Value(receiveAmount);
  static Insertable<SwapsData> custom({
    Expression<int>? id,
    Expression<String>? sendAsset,
    Expression<String>? receiveAsset,
    Expression<int>? sendAmount,
    Expression<int>? receiveAmount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sendAsset != null) 'send_asset': sendAsset,
      if (receiveAsset != null) 'receive_asset': receiveAsset,
      if (sendAmount != null) 'send_amount': sendAmount,
      if (receiveAmount != null) 'receive_amount': receiveAmount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SwapsCompanion copyWith({
    Value<int>? id,
    Value<String>? sendAsset,
    Value<String>? receiveAsset,
    Value<int>? sendAmount,
    Value<int>? receiveAmount,
    Value<DateTime>? createdAt,
  }) {
    return SwapsCompanion(
      id: id ?? this.id,
      sendAsset: sendAsset ?? this.sendAsset,
      receiveAsset: receiveAsset ?? this.receiveAsset,
      sendAmount: sendAmount ?? this.sendAmount,
      receiveAmount: receiveAmount ?? this.receiveAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sendAsset.present) {
      map['send_asset'] = Variable<String>(sendAsset.value);
    }
    if (receiveAsset.present) {
      map['receive_asset'] = Variable<String>(receiveAsset.value);
    }
    if (sendAmount.present) {
      map['send_amount'] = Variable<int>(sendAmount.value);
    }
    if (receiveAmount.present) {
      map['receive_amount'] = Variable<int>(receiveAmount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SwapsCompanion(')
          ..write('id: $id, ')
          ..write('sendAsset: $sendAsset, ')
          ..write('receiveAsset: $receiveAsset, ')
          ..write('sendAmount: $sendAmount, ')
          ..write('receiveAmount: $receiveAmount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class Pegs extends Table with TableInfo<Pegs, PegsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Pegs(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<bool> pegIn = GeneratedColumn<bool>(
    'peg_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("peg_in" IN (0, 1))',
    ),
  );
  late final GeneratedColumn<String> sideswapAddress = GeneratedColumn<String>(
    'sideswap_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> payoutAddress = GeneratedColumn<String>(
    'payout_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression(
      'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    pegIn,
    sideswapAddress,
    payoutAddress,
    amount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pegs';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PegsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PegsData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      orderId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}order_id'],
          )!,
      pegIn:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}peg_in'],
          )!,
      sideswapAddress:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sideswap_address'],
          )!,
      payoutAddress:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payout_address'],
          )!,
      amount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}amount'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  Pegs createAlias(String alias) {
    return Pegs(attachedDatabase, alias);
  }
}

class PegsData extends DataClass implements Insertable<PegsData> {
  final int id;
  final String orderId;
  final bool pegIn;
  final String sideswapAddress;
  final String payoutAddress;
  final int amount;
  final DateTime createdAt;
  const PegsData({
    required this.id,
    required this.orderId,
    required this.pegIn,
    required this.sideswapAddress,
    required this.payoutAddress,
    required this.amount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order_id'] = Variable<String>(orderId);
    map['peg_in'] = Variable<bool>(pegIn);
    map['sideswap_address'] = Variable<String>(sideswapAddress);
    map['payout_address'] = Variable<String>(payoutAddress);
    map['amount'] = Variable<int>(amount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PegsCompanion toCompanion(bool nullToAbsent) {
    return PegsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      pegIn: Value(pegIn),
      sideswapAddress: Value(sideswapAddress),
      payoutAddress: Value(payoutAddress),
      amount: Value(amount),
      createdAt: Value(createdAt),
    );
  }

  factory PegsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PegsData(
      id: serializer.fromJson<int>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      pegIn: serializer.fromJson<bool>(json['pegIn']),
      sideswapAddress: serializer.fromJson<String>(json['sideswapAddress']),
      payoutAddress: serializer.fromJson<String>(json['payoutAddress']),
      amount: serializer.fromJson<int>(json['amount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderId': serializer.toJson<String>(orderId),
      'pegIn': serializer.toJson<bool>(pegIn),
      'sideswapAddress': serializer.toJson<String>(sideswapAddress),
      'payoutAddress': serializer.toJson<String>(payoutAddress),
      'amount': serializer.toJson<int>(amount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PegsData copyWith({
    int? id,
    String? orderId,
    bool? pegIn,
    String? sideswapAddress,
    String? payoutAddress,
    int? amount,
    DateTime? createdAt,
  }) => PegsData(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    pegIn: pegIn ?? this.pegIn,
    sideswapAddress: sideswapAddress ?? this.sideswapAddress,
    payoutAddress: payoutAddress ?? this.payoutAddress,
    amount: amount ?? this.amount,
    createdAt: createdAt ?? this.createdAt,
  );
  PegsData copyWithCompanion(PegsCompanion data) {
    return PegsData(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      pegIn: data.pegIn.present ? data.pegIn.value : this.pegIn,
      sideswapAddress:
          data.sideswapAddress.present
              ? data.sideswapAddress.value
              : this.sideswapAddress,
      payoutAddress:
          data.payoutAddress.present
              ? data.payoutAddress.value
              : this.payoutAddress,
      amount: data.amount.present ? data.amount.value : this.amount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PegsData(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('pegIn: $pegIn, ')
          ..write('sideswapAddress: $sideswapAddress, ')
          ..write('payoutAddress: $payoutAddress, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderId,
    pegIn,
    sideswapAddress,
    payoutAddress,
    amount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PegsData &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.pegIn == this.pegIn &&
          other.sideswapAddress == this.sideswapAddress &&
          other.payoutAddress == this.payoutAddress &&
          other.amount == this.amount &&
          other.createdAt == this.createdAt);
}

class PegsCompanion extends UpdateCompanion<PegsData> {
  final Value<int> id;
  final Value<String> orderId;
  final Value<bool> pegIn;
  final Value<String> sideswapAddress;
  final Value<String> payoutAddress;
  final Value<int> amount;
  final Value<DateTime> createdAt;
  const PegsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.pegIn = const Value.absent(),
    this.sideswapAddress = const Value.absent(),
    this.payoutAddress = const Value.absent(),
    this.amount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PegsCompanion.insert({
    this.id = const Value.absent(),
    required String orderId,
    required bool pegIn,
    required String sideswapAddress,
    required String payoutAddress,
    required int amount,
    this.createdAt = const Value.absent(),
  }) : orderId = Value(orderId),
       pegIn = Value(pegIn),
       sideswapAddress = Value(sideswapAddress),
       payoutAddress = Value(payoutAddress),
       amount = Value(amount);
  static Insertable<PegsData> custom({
    Expression<int>? id,
    Expression<String>? orderId,
    Expression<bool>? pegIn,
    Expression<String>? sideswapAddress,
    Expression<String>? payoutAddress,
    Expression<int>? amount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (pegIn != null) 'peg_in': pegIn,
      if (sideswapAddress != null) 'sideswap_address': sideswapAddress,
      if (payoutAddress != null) 'payout_address': payoutAddress,
      if (amount != null) 'amount': amount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PegsCompanion copyWith({
    Value<int>? id,
    Value<String>? orderId,
    Value<bool>? pegIn,
    Value<String>? sideswapAddress,
    Value<String>? payoutAddress,
    Value<int>? amount,
    Value<DateTime>? createdAt,
  }) {
    return PegsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      pegIn: pegIn ?? this.pegIn,
      sideswapAddress: sideswapAddress ?? this.sideswapAddress,
      payoutAddress: payoutAddress ?? this.payoutAddress,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (pegIn.present) {
      map['peg_in'] = Variable<bool>(pegIn.value);
    }
    if (sideswapAddress.present) {
      map['sideswap_address'] = Variable<String>(sideswapAddress.value);
    }
    if (payoutAddress.present) {
      map['payout_address'] = Variable<String>(payoutAddress.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PegsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('pegIn: $pegIn, ')
          ..write('sideswapAddress: $sideswapAddress, ')
          ..write('payoutAddress: $payoutAddress, ')
          ..write('amount: $amount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class Deposits extends Table with TableInfo<Deposits, DepositsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Deposits(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<BigInt> assetAmount = GeneratedColumn<BigInt>(
    'asset_amount',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  late final GeneratedColumn<String> depositId = GeneratedColumn<String>(
    'deposit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> amountInCents = GeneratedColumn<int>(
    'amount_in_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression(
      'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)',
    ),
  );
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> blockchainTxid = GeneratedColumn<String>(
    'blockchain_txid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    assetAmount,
    id,
    depositId,
    assetId,
    amountInCents,
    createdAt,
    status,
    blockchainTxid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deposits';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DepositsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DepositsData(
      assetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}asset_amount'],
      ),
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      depositId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}deposit_id'],
          )!,
      assetId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}asset_id'],
          )!,
      amountInCents:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}amount_in_cents'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      blockchainTxid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blockchain_txid'],
      ),
    );
  }

  @override
  Deposits createAlias(String alias) {
    return Deposits(attachedDatabase, alias);
  }
}

class DepositsData extends DataClass implements Insertable<DepositsData> {
  final BigInt? assetAmount;
  final int id;
  final String depositId;
  final String assetId;
  final int amountInCents;
  final DateTime createdAt;
  final String status;
  final String? blockchainTxid;
  const DepositsData({
    this.assetAmount,
    required this.id,
    required this.depositId,
    required this.assetId,
    required this.amountInCents,
    required this.createdAt,
    required this.status,
    this.blockchainTxid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || assetAmount != null) {
      map['asset_amount'] = Variable<BigInt>(assetAmount);
    }
    map['id'] = Variable<int>(id);
    map['deposit_id'] = Variable<String>(depositId);
    map['asset_id'] = Variable<String>(assetId);
    map['amount_in_cents'] = Variable<int>(amountInCents);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || blockchainTxid != null) {
      map['blockchain_txid'] = Variable<String>(blockchainTxid);
    }
    return map;
  }

  DepositsCompanion toCompanion(bool nullToAbsent) {
    return DepositsCompanion(
      assetAmount:
          assetAmount == null && nullToAbsent
              ? const Value.absent()
              : Value(assetAmount),
      id: Value(id),
      depositId: Value(depositId),
      assetId: Value(assetId),
      amountInCents: Value(amountInCents),
      createdAt: Value(createdAt),
      status: Value(status),
      blockchainTxid:
          blockchainTxid == null && nullToAbsent
              ? const Value.absent()
              : Value(blockchainTxid),
    );
  }

  factory DepositsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DepositsData(
      assetAmount: serializer.fromJson<BigInt?>(json['assetAmount']),
      id: serializer.fromJson<int>(json['id']),
      depositId: serializer.fromJson<String>(json['depositId']),
      assetId: serializer.fromJson<String>(json['assetId']),
      amountInCents: serializer.fromJson<int>(json['amountInCents']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      blockchainTxid: serializer.fromJson<String?>(json['blockchainTxid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetAmount': serializer.toJson<BigInt?>(assetAmount),
      'id': serializer.toJson<int>(id),
      'depositId': serializer.toJson<String>(depositId),
      'assetId': serializer.toJson<String>(assetId),
      'amountInCents': serializer.toJson<int>(amountInCents),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
      'blockchainTxid': serializer.toJson<String?>(blockchainTxid),
    };
  }

  DepositsData copyWith({
    Value<BigInt?> assetAmount = const Value.absent(),
    int? id,
    String? depositId,
    String? assetId,
    int? amountInCents,
    DateTime? createdAt,
    String? status,
    Value<String?> blockchainTxid = const Value.absent(),
  }) => DepositsData(
    assetAmount: assetAmount.present ? assetAmount.value : this.assetAmount,
    id: id ?? this.id,
    depositId: depositId ?? this.depositId,
    assetId: assetId ?? this.assetId,
    amountInCents: amountInCents ?? this.amountInCents,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    blockchainTxid:
        blockchainTxid.present ? blockchainTxid.value : this.blockchainTxid,
  );
  DepositsData copyWithCompanion(DepositsCompanion data) {
    return DepositsData(
      assetAmount:
          data.assetAmount.present ? data.assetAmount.value : this.assetAmount,
      id: data.id.present ? data.id.value : this.id,
      depositId: data.depositId.present ? data.depositId.value : this.depositId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      amountInCents:
          data.amountInCents.present
              ? data.amountInCents.value
              : this.amountInCents,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      blockchainTxid:
          data.blockchainTxid.present
              ? data.blockchainTxid.value
              : this.blockchainTxid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DepositsData(')
          ..write('assetAmount: $assetAmount, ')
          ..write('id: $id, ')
          ..write('depositId: $depositId, ')
          ..write('assetId: $assetId, ')
          ..write('amountInCents: $amountInCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('blockchainTxid: $blockchainTxid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    assetAmount,
    id,
    depositId,
    assetId,
    amountInCents,
    createdAt,
    status,
    blockchainTxid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DepositsData &&
          other.assetAmount == this.assetAmount &&
          other.id == this.id &&
          other.depositId == this.depositId &&
          other.assetId == this.assetId &&
          other.amountInCents == this.amountInCents &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.blockchainTxid == this.blockchainTxid);
}

class DepositsCompanion extends UpdateCompanion<DepositsData> {
  final Value<BigInt?> assetAmount;
  final Value<int> id;
  final Value<String> depositId;
  final Value<String> assetId;
  final Value<int> amountInCents;
  final Value<DateTime> createdAt;
  final Value<String> status;
  final Value<String?> blockchainTxid;
  const DepositsCompanion({
    this.assetAmount = const Value.absent(),
    this.id = const Value.absent(),
    this.depositId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.amountInCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.blockchainTxid = const Value.absent(),
  });
  DepositsCompanion.insert({
    this.assetAmount = const Value.absent(),
    this.id = const Value.absent(),
    required String depositId,
    required String assetId,
    required int amountInCents,
    this.createdAt = const Value.absent(),
    required String status,
    this.blockchainTxid = const Value.absent(),
  }) : depositId = Value(depositId),
       assetId = Value(assetId),
       amountInCents = Value(amountInCents),
       status = Value(status);
  static Insertable<DepositsData> custom({
    Expression<BigInt>? assetAmount,
    Expression<int>? id,
    Expression<String>? depositId,
    Expression<String>? assetId,
    Expression<int>? amountInCents,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<String>? blockchainTxid,
  }) {
    return RawValuesInsertable({
      if (assetAmount != null) 'asset_amount': assetAmount,
      if (id != null) 'id': id,
      if (depositId != null) 'deposit_id': depositId,
      if (assetId != null) 'asset_id': assetId,
      if (amountInCents != null) 'amount_in_cents': amountInCents,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (blockchainTxid != null) 'blockchain_txid': blockchainTxid,
    });
  }

  DepositsCompanion copyWith({
    Value<BigInt?>? assetAmount,
    Value<int>? id,
    Value<String>? depositId,
    Value<String>? assetId,
    Value<int>? amountInCents,
    Value<DateTime>? createdAt,
    Value<String>? status,
    Value<String?>? blockchainTxid,
  }) {
    return DepositsCompanion(
      assetAmount: assetAmount ?? this.assetAmount,
      id: id ?? this.id,
      depositId: depositId ?? this.depositId,
      assetId: assetId ?? this.assetId,
      amountInCents: amountInCents ?? this.amountInCents,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      blockchainTxid: blockchainTxid ?? this.blockchainTxid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetAmount.present) {
      map['asset_amount'] = Variable<BigInt>(assetAmount.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (depositId.present) {
      map['deposit_id'] = Variable<String>(depositId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (amountInCents.present) {
      map['amount_in_cents'] = Variable<int>(amountInCents.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (blockchainTxid.present) {
      map['blockchain_txid'] = Variable<String>(blockchainTxid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DepositsCompanion(')
          ..write('assetAmount: $assetAmount, ')
          ..write('id: $id, ')
          ..write('depositId: $depositId, ')
          ..write('assetId: $assetId, ')
          ..write('amountInCents: $amountInCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('blockchainTxid: $blockchainTxid')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV4 extends GeneratedDatabase {
  DatabaseAtV4(QueryExecutor e) : super(e);
  late final Swaps swaps = Swaps(this);
  late final Pegs pegs = Pegs(this);
  late final Deposits deposits = Deposits(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [swaps, pegs, deposits];
  @override
  int get schemaVersion => 4;
}
