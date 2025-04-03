import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PegOperation {
  final String orderId;
  final bool isPegIn;
  final DateTime createdAt;

  PegOperation({
    required this.orderId,
    required this.isPegIn,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'isPegIn': isPegIn,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory PegOperation.fromJson(Map<String, dynamic> json) {
    return PegOperation(
      orderId: json['orderId'],
      isPegIn: json['isPegIn'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}

class PegPersistenceService {
  static const String _activePegKey = 'active_peg_operation';

  Future<void> saveActivePegOperation(PegOperation operation) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activePegKey, jsonEncode(operation.toJson()));
  }

  Future<PegOperation?> getActivePegOperation() async {
    final prefs = await SharedPreferences.getInstance();
    final operationJson = prefs.getString(_activePegKey);

    if (operationJson == null) return null;

    try {
      return PegOperation.fromJson(jsonDecode(operationJson));
    } catch (e) {
      await clearActivePegOperation();
      return null;
    }
  }

  Future<void> clearActivePegOperation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activePegKey);
  }

  bool isOperationValid(PegOperation operation) {
    final validUntil = operation.createdAt.add(const Duration(minutes: 15));
    return DateTime.now().isBefore(validUntil);
  }
}
