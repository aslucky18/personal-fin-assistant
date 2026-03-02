import 'package:shared_preferences/shared_preferences.dart';
import '../models/pending_transaction.dart';

const String _kPendingKey = 'pending_transactions_v1';

/// Manages the local pending transaction queue using SharedPreferences.
class PendingTransactionService {
  static PendingTransactionService? _instance;
  PendingTransactionService._();
  static PendingTransactionService get instance =>
      _instance ??= PendingTransactionService._();

  Future<List<PendingTransaction>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPendingKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return PendingTransaction.listFromJson(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> add(PendingTransaction tx) async {
    final list = await getAll();
    // Deduplicate: don't add the same SMS twice (same amount, type, accountEndsWith, within 1 min)
    final isDuplicate = list.any(
      (existing) =>
          existing.amount == tx.amount &&
          existing.type == tx.type &&
          existing.accountEndsWith == tx.accountEndsWith &&
          tx.timestamp.difference(existing.timestamp).abs().inMinutes < 1,
    );
    if (isDuplicate) return;
    list.insert(0, tx);
    await _save(list);
  }

  Future<void> update(PendingTransaction tx) async {
    final list = await getAll();
    final idx = list.indexWhere((e) => e.id == tx.id);
    if (idx != -1) {
      list[idx] = tx;
      await _save(list);
    }
  }

  Future<void> remove(String id) async {
    final list = await getAll();
    list.removeWhere((e) => e.id == id);
    await _save(list);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingKey);
  }

  Future<int> pendingCount() async {
    final list = await getAll();
    return list
        .where((t) => t.status == PendingTransactionStatus.pending)
        .length;
  }

  Future<void> _save(List<PendingTransaction> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingKey, PendingTransaction.listToJson(list));
  }
}
