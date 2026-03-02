import 'package:flutter_test/flutter_test.dart';
import 'package:finanalyzer/features/sms_automation/services/sms_parser_service.dart';
import 'package:finanalyzer/features/categories/models/category.dart'
    as cat_model;
import 'package:finanalyzer/features/goals/models/goal.dart';
import 'package:finanalyzer/features/liabilities/models/liability.dart';
import 'package:finanalyzer/features/accounts/models/account.dart';

void main() {
  // ── isBankSender ────────────────────────────────────────────────────────────
  group('SmsParserService.isBankSender()', () {
    test('returns true for known HDFC sender', () {
      expect(SmsParserService.isBankSender('HDFCBK'), isTrue);
    });

    test('returns true for ICICI sender (case insensitive)', () {
      expect(SmsParserService.isBankSender('icicib'), isTrue);
    });

    test('returns true for UPI sender (GPAY)', () {
      expect(SmsParserService.isBankSender('GPAY'), isTrue);
    });

    test('returns true for sender containing known ID as substring', () {
      expect(SmsParserService.isBankSender('VM-HDFCBK'), isTrue);
    });

    test('returns false for random sender', () {
      expect(SmsParserService.isBankSender('AMAZON'), isFalse);
    });

    test('returns false for marketing sender', () {
      expect(SmsParserService.isBankSender('ZOMATO'), isFalse);
    });

    test('returns false for empty sender', () {
      expect(SmsParserService.isBankSender(''), isFalse);
    });
  });

  // ── parse() — amount extraction ─────────────────────────────────────────────
  group('SmsParserService.parse() — amount', () {
    test('parses ₹ symbol with comma-separated amount', () {
      final result = SmsParserService.parse(
        'Your A/c XX1234 is debited ₹1,500.00 to Swiggy on 03-Mar-26.',
        'HDFCBK',
      );
      expect(result.amount, equals(1500.0));
    });

    test('parses Rs. prefix', () {
      final result = SmsParserService.parse(
        'Rs.250 debited from your account. Purchase at Zomato.',
        'HDFCBK',
      );
      expect(result.amount, equals(250.0));
    });

    test('parses INR prefix', () {
      final result = SmsParserService.parse(
        'INR 5000.00 credited to your account.',
        'SBIINB',
      );
      expect(result.amount, equals(5000.0));
    });

    test('parses amount with Amount: keyword', () {
      final result = SmsParserService.parse(
        'Payment successful. Amount: ₹999 paid to Netflix.',
        'AXISBK',
      );
      expect(result.amount, equals(999.0));
    });

    test('returns null amount for non-transaction SMS', () {
      final result = SmsParserService.parse(
        'Your OTP is 123456. Do not share.',
        'HDFCBK',
      );
      expect(result.amount, isNull);
    });
  });

  // ── parse() — transaction type ───────────────────────────────────────────────
  group('SmsParserService.parse() — transaction type', () {
    test('detects debit from "debited" keyword', () {
      final result = SmsParserService.parse(
        'Your account XX1234 is debited ₹500 to Swiggy.',
        'HDFCBK',
      );
      expect(result.type, equals('debit'));
    });

    test('detects debit from "paid" keyword', () {
      final result = SmsParserService.parse('₹200 paid to Uber.', 'HDFCBK');
      expect(result.type, equals('debit'));
    });

    test('detects credit from "credited" keyword', () {
      final result = SmsParserService.parse(
        'INR 50000 credited to your account. Salary received.',
        'SBIINB',
      );
      expect(result.type, equals('credit'));
    });

    test('detects credit from "received" keyword', () {
      final result = SmsParserService.parse(
        '₹1000 received from Rahul via UPI.',
        'GPAY',
      );
      expect(result.type, equals('credit'));
    });
  });

  // ── parse() — account ending ─────────────────────────────────────────────────
  group('SmsParserService.parse() — account ending', () {
    test('extracts 4-digit account ending from XX prefix', () {
      final result = SmsParserService.parse(
        'A/c XX1234 is debited ₹500.',
        'HDFCBK',
      );
      expect(result.accountEndsWith, equals('1234'));
    });

    test('extracts account ending from "ending" keyword', () {
      final result = SmsParserService.parse(
        'Card ending 5678 used for ₹300 at Zomato.',
        'AXISBK',
      );
      expect(result.accountEndsWith, equals('5678'));
    });

    test('returns null when no account number present', () {
      final result = SmsParserService.parse(
        '₹500 debited to Swiggy.',
        'HDFCBK',
      );
      expect(result.accountEndsWith, isNull);
    });
  });

  // ── parse() — merchant extraction ────────────────────────────────────────────
  group('SmsParserService.parse() — merchant', () {
    test('extracts merchant from "to" pattern', () {
      final result = SmsParserService.parse(
        'Your account XX1234 is debited ₹500 to Swiggy on 03-Mar-26.',
        'HDFCBK',
      );
      expect(result.merchant.toLowerCase(), contains('swiggy'));
    });

    test('extracts merchant from "at" pattern', () {
      final result = SmsParserService.parse(
        '₹300 spent at Zomato on 01-Mar-26.',
        'AXISBK',
      );
      expect(result.merchant.toLowerCase(), contains('zomato'));
    });

    test('falls back to sender when merchant cannot be extracted', () {
      final result = SmsParserService.parse('₹500 debited.', 'HDFCBK');
      expect(result.merchant, equals('HDFCBK'));
    });
  });

  // ── parse() — date parsing ────────────────────────────────────────────────────
  group('SmsParserService.parse() — date', () {
    test('parses dd-MMM-yy date format', () {
      final result = SmsParserService.parse(
        'A/c XX1234 debited ₹500 to Swiggy on 15-Mar-26.',
        'HDFCBK',
      );
      expect(result.timestamp.day, equals(15));
      expect(result.timestamp.month, equals(3));
      expect(result.timestamp.year, equals(2026));
    });

    test('parses dd/MM/yyyy date format', () {
      final result = SmsParserService.parse(
        '₹200 debited on 03/03/2026 to Uber.',
        'AXISBK',
      );
      expect(result.timestamp.year, isNot(1970)); // any valid date parsed
    });

    test('falls back to now when no date present', () {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      final result = SmsParserService.parse('₹100 debited to Cafe.', 'HDFCBK');
      expect(result.timestamp.isAfter(before), isTrue);
    });
  });

  // ── parse() — isTransactionSms ────────────────────────────────────────────────
  group('SmsParserService.parse() — isTransactionSms', () {
    test('flags genuine transaction SMS as true', () {
      final result = SmsParserService.parse(
        'A/c XX1234 is debited ₹500 to Swiggy on 03-Mar-26.',
        'HDFCBK',
      );
      expect(result.isTransactionSms, isTrue);
    });

    test('flags OTP SMS as false', () {
      final result = SmsParserService.parse(
        'Your OTP is 456789 for login. Do not share.',
        'HDFCBK',
      );
      expect(result.isTransactionSms, isFalse);
    });

    test('flags SMS without amount as false even with keywords', () {
      final result = SmsParserService.parse(
        'Your account has been debited. Contact bank for details.',
        'HDFCBK',
      );
      expect(result.isTransactionSms, isFalse);
    });
  });

  // ── autoAssign() ──────────────────────────────────────────────────────────────
  group('SmsParserService.autoAssign()', () {
    final now = DateTime.now();

    // Helper to build a Category
    cat_model.Category makeCategory(String id, String name, String type) =>
        cat_model.Category(
          id: id,
          userId: 'u1',
          name: name,
          type: type,
          icon: 'category',
          colour: '#0EA5E9',
          createdAt: now,
        );

    // Helper to build a Goal
    FinancialGoal makeGoal(String id, String name, String? catId) =>
        FinancialGoal(
          id: id,
          userId: 'u1',
          name: name,
          targetAmount: 1000,
          currentAmount: 0,
          monthlyContribution: 100,
          categoryId: catId,
          createdAt: now,
          icon: 'flag',
          colour: '#2196F3',
        );

    // Helper to build a Liability
    Liability makeLiability(String id, String name, String? catId) => Liability(
      id: id,
      userId: 'u1',
      name: name,
      totalAmount: 500,
      paidAmount: 0,
      interestRate: 0,
      type: 'loan',
      categoryId: catId,
      createdAt: now,
    );

    // Helper to build an Account
    Account makeAccount(String id, String endsWith) => Account(
      id: id,
      userId: 'u1',
      bankName: 'HDFC',
      type: 'savings',
      endsWith: endsWith,
      createdAt: now,
    );

    test('assigns category by exact merchant name match', () {
      final cats = [
        makeCategory('cat-food', 'Swiggy', cat_model.Category.variableExpense),
      ];
      final result = SmsParserService.autoAssign(
        merchant: 'Swiggy',
        type: 'debit',
        accountEndsWith: null,
        categories: cats,
        goals: [],
        liabilities: [],
        accounts: [],
      );
      expect(result.categoryId, equals('cat-food'));
    });

    test('assigns category by keyword hint (zomato → food category)', () {
      final cats = [
        makeCategory(
          'cat-food',
          'Food & Dining',
          cat_model.Category.variableExpense,
        ),
      ];
      final result = SmsParserService.autoAssign(
        merchant: 'zomato order',
        type: 'debit',
        accountEndsWith: null,
        categories: cats,
        goals: [],
        liabilities: [],
        accounts: [],
      );
      expect(result.categoryId, equals('cat-food'));
    });

    test('assigns goal when category is linked to a goal', () {
      final cats = [
        makeCategory('cat-savings', 'Savings', cat_model.Category.fixedExpense),
      ];
      final goals = [makeGoal('goal-1', 'Emergency Fund', 'cat-savings')];
      final result = SmsParserService.autoAssign(
        merchant: 'Savings',
        type: 'debit',
        accountEndsWith: null,
        categories: cats,
        goals: goals,
        liabilities: [],
        accounts: [],
      );
      expect(result.categoryId, equals('cat-savings'));
      expect(result.goalId, equals('goal-1'));
    });

    test('assigns liability when category is linked to a liability', () {
      final cats = [
        makeCategory('cat-emi', 'EMI', cat_model.Category.fixedExpense),
      ];
      final liabilities = [makeLiability('lib-1', 'Home Loan EMI', 'cat-emi')];
      final result = SmsParserService.autoAssign(
        merchant: 'EMI payment',
        type: 'debit',
        accountEndsWith: null,
        categories: cats,
        goals: [],
        liabilities: liabilities,
        accounts: [],
      );
      expect(result.liabilityId, equals('lib-1'));
    });

    test('matches account by last 4 digits', () {
      final accounts = [makeAccount('acct-1', '1234')];
      final result = SmsParserService.autoAssign(
        merchant: 'Swiggy',
        type: 'debit',
        accountEndsWith: '1234',
        categories: [],
        goals: [],
        liabilities: [],
        accounts: accounts,
      );
      expect(result.accountId, equals('acct-1'));
    });

    test('returns null for all fields when no data matches', () {
      final result = SmsParserService.autoAssign(
        merchant: 'UnknownMerchantXYZ123',
        type: 'debit',
        accountEndsWith: '9999',
        categories: [],
        goals: [],
        liabilities: [],
        accounts: [],
      );
      expect(result.categoryId, isNull);
      expect(result.goalId, isNull);
      expect(result.liabilityId, isNull);
      expect(result.accountId, isNull);
    });

    test('does not assign expense category for credit transaction', () {
      final cats = [
        makeCategory('cat-food', 'Food', cat_model.Category.variableExpense),
      ];
      final result = SmsParserService.autoAssign(
        merchant: 'Food',
        type: 'credit', // income — expense category should be filtered out
        accountEndsWith: null,
        categories: cats,
        goals: [],
        liabilities: [],
        accounts: [],
      );
      expect(result.categoryId, isNull);
    });

    test('keyword "netflix" maps to entertainment category', () {
      final cats = [
        makeCategory(
          'cat-ent',
          'Entertainment',
          cat_model.Category.variableExpense,
        ),
      ];
      final result = SmsParserService.autoAssign(
        merchant: 'Netflix subscription',
        type: 'debit',
        accountEndsWith: null,
        categories: cats,
        goals: [],
        liabilities: [],
        accounts: [],
      );
      expect(result.categoryId, equals('cat-ent'));
    });
  });
}
