import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finanalyzer/features/sms_automation/services/pending_transaction_service.dart';
import 'package:finanalyzer/features/sms_automation/models/pending_transaction.dart';

void main() {
  late PendingTransactionService service;

  setUp(() {
    // Reset SharedPreferences to empty state before every test
    SharedPreferences.setMockInitialValues({});
    // Reset the singleton so each test starts fresh
    service = PendingTransactionService.instance;
  });

  final baseTime = DateTime(2026, 3, 3, 10, 0);

  PendingTransaction makeTx({
    String id = 'tx-1',
    double amount = 500.0,
    String type = 'debit',
    String? accountEndsWith = '1234',
    DateTime? timestamp,
    PendingTransactionStatus status = PendingTransactionStatus.pending,
  }) => PendingTransaction(
    id: id,
    rawSms: 'Test SMS',
    sender: 'HDFCBK',
    amount: amount,
    type: type,
    accountEndsWith: accountEndsWith,
    merchant: 'Swiggy',
    timestamp: timestamp ?? baseTime,
    status: status,
  );

  // ── getAll ───────────────────────────────────────────────────────────────────
  group('PendingTransactionService.getAll()', () {
    test('returns empty list when nothing stored', () async {
      final list = await service.getAll();
      expect(list, isEmpty);
    });

    test('returns empty list when stored data is invalid JSON', () async {
      SharedPreferences.setMockInitialValues({
        'pending_transactions_v1': 'not_valid_json',
      });
      final list = await service.getAll();
      expect(list, isEmpty);
    });
  });

  // ── add ──────────────────────────────────────────────────────────────────────
  group('PendingTransactionService.add()', () {
    test('adds a transaction and retrieves it', () async {
      final tx = makeTx();
      await service.add(tx);
      final list = await service.getAll();
      expect(list.length, equals(1));
      expect(list.first.id, equals('tx-1'));
    });

    test('adds multiple transactions in reverse-insertion order', () async {
      await service.add(makeTx(id: 'tx-1'));
      await service.add(makeTx(id: 'tx-2', amount: 200.0));
      final list = await service.getAll();
      expect(list.length, equals(2));
      // Most recently added is at index 0
      expect(list.first.id, equals('tx-2'));
    });

    test('deduplicates identical transactions within 1 minute', () async {
      final tx1 = makeTx(id: 'tx-1', timestamp: baseTime);
      final tx2 = makeTx(
        id: 'tx-2',
        timestamp: baseTime.add(const Duration(seconds: 30)),
      ); // same amount/type/account, within 1 min
      await service.add(tx1);
      await service.add(tx2);
      final list = await service.getAll();
      expect(list.length, equals(1)); // duplicate rejected
    });

    test(
      'does NOT deduplicate transactions more than 1 minute apart',
      () async {
        final tx1 = makeTx(id: 'tx-1', timestamp: baseTime);
        final tx2 = makeTx(
          id: 'tx-2',
          timestamp: baseTime.add(const Duration(minutes: 2)),
        );
        await service.add(tx1);
        await service.add(tx2);
        final list = await service.getAll();
        expect(list.length, equals(2));
      },
    );

    test('does NOT deduplicate transactions with different amounts', () async {
      await service.add(makeTx(id: 'tx-1', amount: 100.0));
      await service.add(makeTx(id: 'tx-2', amount: 200.0));
      final list = await service.getAll();
      expect(list.length, equals(2));
    });

    test(
      'does NOT deduplicate transactions with different account endings',
      () async {
        await service.add(makeTx(id: 'tx-1', accountEndsWith: '1234'));
        await service.add(makeTx(id: 'tx-2', accountEndsWith: '5678'));
        final list = await service.getAll();
        expect(list.length, equals(2));
      },
    );
  });

  // ── update ───────────────────────────────────────────────────────────────────
  group('PendingTransactionService.update()', () {
    test('updates the status of an existing transaction', () async {
      await service.add(makeTx(id: 'tx-1'));
      final updated = makeTx(
        id: 'tx-1',
      ).copyWith(status: PendingTransactionStatus.approved);
      await service.update(updated);
      final list = await service.getAll();
      expect(list.first.status, equals(PendingTransactionStatus.approved));
    });

    test('does nothing if transaction id does not exist', () async {
      await service.add(makeTx(id: 'tx-1'));
      final ghost = makeTx(
        id: 'ghost-tx',
      ).copyWith(status: PendingTransactionStatus.rejected);
      await service.update(ghost);
      final list = await service.getAll();
      expect(list.length, equals(1));
      expect(list.first.status, equals(PendingTransactionStatus.pending));
    });
  });

  // ── remove ───────────────────────────────────────────────────────────────────
  group('PendingTransactionService.remove()', () {
    test('removes a transaction by id', () async {
      await service.add(makeTx(id: 'tx-1'));
      await service.add(makeTx(id: 'tx-2', amount: 200.0));
      await service.remove('tx-1');
      final list = await service.getAll();
      expect(list.length, equals(1));
      expect(list.first.id, equals('tx-2'));
    });

    test('does nothing if id does not exist', () async {
      await service.add(makeTx(id: 'tx-1'));
      await service.remove('nonexistent');
      final list = await service.getAll();
      expect(list.length, equals(1));
    });
  });

  // ── clearAll ─────────────────────────────────────────────────────────────────
  group('PendingTransactionService.clearAll()', () {
    test('removes all transactions', () async {
      await service.add(makeTx(id: 'tx-1'));
      await service.add(makeTx(id: 'tx-2', amount: 200.0));
      await service.clearAll();
      final list = await service.getAll();
      expect(list, isEmpty);
    });

    test('clearAll on empty storage does not throw', () async {
      expect(() async => service.clearAll(), returnsNormally);
    });
  });

  // ── pendingCount ─────────────────────────────────────────────────────────────
  group('PendingTransactionService.pendingCount()', () {
    test('returns 0 when empty', () async {
      expect(await service.pendingCount(), equals(0));
    });

    test('counts only pending transactions', () async {
      await service.add(makeTx(id: 'tx-1')); // pending
      await service.add(makeTx(id: 'tx-2', amount: 200.0)); // pending
      // approve tx-1
      await service.update(
        makeTx(id: 'tx-1').copyWith(status: PendingTransactionStatus.approved),
      );
      expect(await service.pendingCount(), equals(1));
    });

    test('does not count rejected transactions', () async {
      await service.add(makeTx(id: 'tx-1'));
      await service.update(
        makeTx(id: 'tx-1').copyWith(status: PendingTransactionStatus.rejected),
      );
      expect(await service.pendingCount(), equals(0));
    });
  });
}
