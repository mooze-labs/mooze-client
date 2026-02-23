import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pending_transaction.dart';

class PendingTransactionStorage {
  static const String _storageKey = 'pending_transactions';

  Future<List<PendingTransaction>> getPendingTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map(
            (json) => PendingTransaction.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> savePendingTransaction(PendingTransaction transaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentTransactions = await getPendingTransactions();

      if (!currentTransactions.contains(transaction)) {
        currentTransactions.add(transaction);
        await _saveAll(prefs, currentTransactions);
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> savePendingTransactions(
    List<PendingTransaction> transactions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _saveAll(prefs, transactions);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> removePendingTransaction(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentTransactions = await getPendingTransactions();

      final updatedTransactions =
          currentTransactions.where((t) => t.id != transactionId).toList();

      await _saveAll(prefs, updatedTransactions);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _saveAll(
    SharedPreferences prefs,
    List<PendingTransaction> transactions,
  ) async {
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<bool> hasPendingTransaction(String transactionId) async {
    final transactions = await getPendingTransactions();
    return transactions.any((t) => t.id == transactionId);
  }
}
