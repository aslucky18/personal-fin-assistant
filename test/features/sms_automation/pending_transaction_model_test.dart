import 'package:flutter_test/flutter_test.dart';
import 'package:finanalyzer/features/sms_automation/models/pending_transaction.dart';

void main() {
  final testTimestamp = DateTime(2026, 3, 3, 10, 30);

  PendingTransaction makeTx({
    String id = 'tx-1',
    String rawSms = 'Test SMS body',
    String sender = 'HDFCBK',
    double amount = 500.0,
    String type = 'debit',
    String? accountEndsWith = '1234',
    String merchant = 'Swiggy',
    PendingTransactionStatus status = PendingTransactionStatus.pending,
    String? categoryId,
    String? goalId,
    String? liabilityId,
    String? accountId,
  }) => PendingTransaction(
    id: id,
    rawSms: rawSms,
    sender: sender,
    amount: amount,
    type: type,
    accountEndsWith: accountEndsWith,
    merchant: merchant,
    timestamp: testTimestamp,
    status: status,
    categoryId: categoryId,
    goalId: goalId,
    liabilityId: liabilityId,
    accountId: accountId,
  );

  // ── toJson / fromJson ────────────────────────────────────────────────────────
  group('PendingTransaction — JSON serialization', () {
    test('toJson contains all expected keys', () {
      final tx = makeTx(categoryId: 'cat-1', goalId: 'goal-1');
      final json = tx.toJson();
      expect(json['id'], equals('tx-1'));
      expect(json['amount'], equals(500.0));
      expect(json['type'], equals('debit'));
      expect(json['merchant'], equals('Swiggy'));
      expect(json['accountEndsWith'], equals('1234'));
      expect(json['status'], equals('pending'));
      expect(json['categoryId'], equals('cat-1'));
      expect(json['goalId'], equals('goal-1'));
      expect(json['liabilityId'], isNull);
      expect(json['accountId'], isNull);
    });

    test('fromJson reconstructs all fields correctly', () {
      final tx = makeTx(categoryId: 'cat-1', accountId: 'acct-1');
      final json = tx.toJson();
      final restored = PendingTransaction.fromJson(json);

      expect(restored.id, equals(tx.id));
      expect(restored.amount, equals(tx.amount));
      expect(restored.type, equals(tx.type));
      expect(restored.merchant, equals(tx.merchant));
      expect(restored.accountEndsWith, equals(tx.accountEndsWith));
      expect(restored.status, equals(tx.status));
      expect(restored.categoryId, equals('cat-1'));
      expect(restored.accountId, equals('acct-1'));
    });

    test('fromJson handles missing optional fields gracefully', () {
      final json = {
        'id': 'tx-2',
        'rawSms': 'SMS',
        'sender': 'AXISBK',
        'amount': 100.0,
        'type': 'credit',
        'accountEndsWith': null,
        'merchant': 'Salary',
        'timestamp': testTimestamp.toIso8601String(),
        // status, categoryId, goalId, liabilityId, accountId are absent/null
      };
      final tx = PendingTransaction.fromJson(json);
      expect(tx.status, equals(PendingTransactionStatus.pending));
      expect(tx.categoryId, isNull);
      expect(tx.goalId, isNull);
    });

    test('roundtrip: toJson → fromJson preserves timestamp', () {
      final tx = makeTx();
      final restored = PendingTransaction.fromJson(tx.toJson());
      expect(restored.timestamp, equals(testTimestamp));
    });

    test('approved status roundtrips correctly', () {
      final tx = makeTx(status: PendingTransactionStatus.approved);
      final restored = PendingTransaction.fromJson(tx.toJson());
      expect(restored.status, equals(PendingTransactionStatus.approved));
    });

    test('rejected status roundtrips correctly', () {
      final tx = makeTx(status: PendingTransactionStatus.rejected);
      final restored = PendingTransaction.fromJson(tx.toJson());
      expect(restored.status, equals(PendingTransactionStatus.rejected));
    });
  });

  // ── listToJson / listFromJson ─────────────────────────────────────────────────
  group('PendingTransaction — list serialization', () {
    test('listToJson then listFromJson restores the full list', () {
      final list = [
        makeTx(id: 'tx-1', amount: 100.0),
        makeTx(id: 'tx-2', amount: 200.0, type: 'credit'),
      ];
      final json = PendingTransaction.listToJson(list);
      final restored = PendingTransaction.listFromJson(json);

      expect(restored.length, equals(2));
      expect(restored[0].id, equals('tx-1'));
      expect(restored[1].type, equals('credit'));
    });

    test('listFromJson handles empty list', () {
      final restored = PendingTransaction.listFromJson('[]');
      expect(restored, isEmpty);
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────────
  group('PendingTransaction.copyWith()', () {
    test('copies with updated status', () {
      final original = makeTx();
      final updated = original.copyWith(
        status: PendingTransactionStatus.approved,
      );
      expect(updated.status, equals(PendingTransactionStatus.approved));
      expect(updated.id, equals(original.id));
      expect(updated.amount, equals(original.amount));
    });

    test('copies with updated categoryId', () {
      final original = makeTx();
      final updated = original.copyWith(categoryId: 'new-cat');
      expect(updated.categoryId, equals('new-cat'));
      expect(updated.merchant, equals(original.merchant));
    });

    test('copies with updated amount', () {
      final original = makeTx(amount: 100.0);
      final updated = original.copyWith(amount: 999.0);
      expect(updated.amount, equals(999.0));
      expect(original.amount, equals(100.0)); // original unchanged
    });

    test('does not mutate original when copying', () {
      final original = makeTx(type: 'debit');
      original.copyWith(type: 'credit');
      expect(original.type, equals('debit')); // dart models are immutable
    });
  });
}
