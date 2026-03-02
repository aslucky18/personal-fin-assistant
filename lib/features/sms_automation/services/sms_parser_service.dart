import '../../categories/models/category.dart' as cat_model;
import '../../goals/models/goal.dart';
import '../../liabilities/models/liability.dart';
import '../../accounts/models/account.dart';

/// Known Indian bank sender IDs for filtering genuine bank SMS
const List<String> kBankSenderIds = [
  'HDFCBK',
  'HDFCBANK',
  'ICICIB',
  'ICICIBANK',
  'SBIINB',
  'SBIPSG',
  'AXISBK',
  'AXISBANK',
  'KOTAKB',
  'KOTAKBANK',
  'YESBANK',
  'YESBK',
  'INDUSB',
  'SCBANK',
  'RBLBANK',
  'IDFCBK',
  'BOIBK',
  'CANBK',
  'UNIONB',
  'PNBSMS',
  'AUBANK',
  'FEDBK',
  'BANDHAN',
  'PAYTMB',
  'JUSPAY',
  'GPAY',
  'PHONEPE',
  'AMAZONPAY',
];

class ParsedSmsResult {
  final double? amount;
  final String type; // 'debit' or 'credit'
  final String? accountEndsWith;
  final String merchant;
  final DateTime timestamp;
  final bool isTransactionSms;

  ParsedSmsResult({
    this.amount,
    required this.type,
    this.accountEndsWith,
    required this.merchant,
    required this.timestamp,
    required this.isTransactionSms,
  });
}

class SmsParserService {
  /// Returns true if the sender looks like a bank / fintech
  static bool isBankSender(String sender) {
    final upper = sender.toUpperCase();
    return kBankSenderIds.any((id) => upper.contains(id));
  }

  /// Main parse method — call this first
  static ParsedSmsResult parse(String body, String sender) {
    final lower = body.toLowerCase();

    // ── Is it a transaction SMS? ─────────────────────────────────────────────
    final transactionKeywords = [
      'debited',
      'credited',
      'debit',
      'credit',
      'withdrawn',
      'transferred',
      'paid',
      'received',
      'spent',
      'payment',
      'purchase',
    ];
    final isTransaction =
        transactionKeywords.any((k) => lower.contains(k)) &&
        _parseAmount(body) != null;

    // ── Amount ───────────────────────────────────────────────────────────────
    final amount = _parseAmount(body);

    // ── Type ─────────────────────────────────────────────────────────────────
    final debitKeywords = [
      'debited',
      'debit',
      'withdrawn',
      'spent',
      'paid',
      'purchase',
    ];
    final type = debitKeywords.any((k) => lower.contains(k))
        ? 'debit'
        : 'credit';

    // ── Account last 4 digits ────────────────────────────────────────────────
    final accountEndsWith = _parseAccountEnding(body);

    // ── Merchant ─────────────────────────────────────────────────────────────
    final merchant = _parseMerchant(body, sender);

    // ── Timestamp ────────────────────────────────────────────────────────────
    final timestamp = _parseDate(body) ?? DateTime.now();

    return ParsedSmsResult(
      amount: amount,
      type: type,
      accountEndsWith: accountEndsWith,
      merchant: merchant,
      timestamp: timestamp,
      isTransactionSms: isTransaction,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static double? _parseAmount(String body) {
    // Patterns: ₹1,500.00 | Rs.1500 | INR 1500 | USD 1500 | 1,500.00 after keywords
    final patterns = [
      RegExp(
        r'(?:₹|Rs\.?|INR|USD|EUR)\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:amount|amt)[:\s]+(?:₹|Rs\.?|INR)?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        return double.tryParse(raw);
      }
    }
    return null;
  }

  static String? _parseAccountEnding(String body) {
    // Matches: XX1234 | x-1234 | A/c **1234 | ending 1234
    final pattern = RegExp(
      r'(?:xx|x-|a\/c\s*(?:\*+)?|acct?\s*(?:\*+)?|ending\s+)(\d{4})',
      caseSensitive: false,
    );
    return pattern.firstMatch(body)?.group(1);
  }

  static String _parseMerchant(String body, String sender) {
    // Try common patterns
    final patterns = [
      RegExp(
        r'(?:to|at|towards|for)\s+([A-Z][A-Za-z0-9\s&\-.@]{2,40}?)(?:\s+on|\s+via|\s+\.|,|$)',
        caseSensitive: false,
      ),
      RegExp(r'VPA\s+([A-Za-z0-9@._\-]{3,50})', caseSensitive: false),
      RegExp(r'UPI-([A-Za-z0-9@._\-]{3,50})', caseSensitive: false),
      RegExp(
        r'(?:merchant|payee):\s*([A-Za-z0-9\s&\-.]{2,40})',
        caseSensitive: false,
      ),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(body);
      if (m != null) {
        final result = m.group(1)?.trim();
        if (result != null && result.length >= 2) return result;
      }
    }
    // Fallback: use the sender ID
    return sender;
  }

  static DateTime? _parseDate(String body) {
    // dd-MMM-yy or dd/MM/yyyy or dd-MM-yyyy
    final patterns = [
      RegExp(
        r'(\d{2}-(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\d{2,4})',
        caseSensitive: false,
      ),
      RegExp(r'(\d{2}[\/\-]\d{2}[\/\-]\d{4})'),
      RegExp(r'(\d{4}-\d{2}-\d{2})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(body);
      if (m != null) {
        try {
          return _flexibleParse(m.group(1)!);
        } catch (_) {}
      }
    }
    return null;
  }

  static DateTime _flexibleParse(String s) {
    // dd-MMM-yy → e.g. 03-MAR-26
    final monthMap = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final rddMMMyy = RegExp(
      r'(\d{2})-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-(\d{2,4})',
      caseSensitive: false,
    );
    final m = rddMMMyy.firstMatch(s);
    if (m != null) {
      final day = int.parse(m.group(1)!);
      final month = monthMap[m.group(2)!.toLowerCase()]!;
      var year = int.parse(m.group(3)!);
      if (year < 100) year += 2000;
      return DateTime(year, month, day);
    }
    return DateTime.parse(s); // ISO / dd/MM/yyyy fallback
  }

  // ── Auto-assignment ────────────────────────────────────────────────────────

  /// Auto-assigns category, goal, liability IDs based on keyword matching.
  static ({
    String? categoryId,
    String? goalId,
    String? liabilityId,
    String? accountId,
  })
  autoAssign({
    required String merchant,
    required String type,
    required String? accountEndsWith,
    required List<cat_model.Category> categories,
    required List<FinancialGoal> goals,
    required List<Liability> liabilities,
    required List<Account> accounts,
  }) {
    String? categoryId;
    String? goalId;
    String? liabilityId;
    String? accountId;

    final merchantLower = merchant.toLowerCase();

    // ── Category matching ──────────────────────────────────────────────────
    // Filter categories by income/expense type to avoid mismatches
    final isExpense = type == 'debit';
    final relevantCategories = categories.where((c) {
      if (isExpense) {
        return c.type == cat_model.Category.fixedExpense ||
            c.type == cat_model.Category.variableExpense;
      } else {
        return c.type == cat_model.Category.fixedIncome ||
            c.type == cat_model.Category.variableIncome;
      }
    }).toList();

    for (final cat in relevantCategories) {
      if (merchantLower.contains(cat.name.toLowerCase()) ||
          cat.name.toLowerCase().contains(merchantLower.split(' ').first)) {
        categoryId = cat.id;
        break;
      }
    }

    // Keyword-based category matching
    categoryId ??= _guessCategory(merchantLower, isExpense, relevantCategories);

    // ── Goal / Liability matching from category link ────────────────────────
    if (categoryId != null) {
      // Check if any goal is linked to this category
      final matchedGoal = goals
          .where((g) => g.categoryId == categoryId)
          .toList();
      if (matchedGoal.isNotEmpty) goalId = matchedGoal.first.id;

      // Check if any liability is linked to this category
      final matchedLiability = liabilities
          .where((l) => l.categoryId == categoryId)
          .toList();
      if (matchedLiability.isNotEmpty) liabilityId = matchedLiability.first.id;
    }

    // ── Account matching by last 4 digits ─────────────────────────────────
    if (accountEndsWith != null) {
      final matchedAcct = accounts
          .where((a) => a.endsWith == accountEndsWith)
          .toList();
      if (matchedAcct.isNotEmpty) accountId = matchedAcct.first.id;
    }

    return (
      categoryId: categoryId,
      goalId: goalId,
      liabilityId: liabilityId,
      accountId: accountId,
    );
  }

  static String? _guessCategory(
    String merchantLower,
    bool isExpense,
    List<cat_model.Category> cats,
  ) {
    // Keyword → category name hints
    final keywordMap = {
      'swiggy': 'food',
      'zomato': 'food',
      'uber eats': 'food',
      'restaurant': 'food',
      'cafe': 'food',
      'ola': 'transport',
      'uber': 'transport',
      'metro': 'transport',
      'petrol': 'fuel',
      'diesel': 'fuel',
      'hp ': 'fuel',
      'electricity': 'utilities',
      'water': 'utilities',
      'airtel': 'utilities',
      'jio': 'utilities',
      'vodafone': 'utilities',
      'netflix': 'entertainment',
      'hotstar': 'entertainment',
      'prime': 'entertainment',
      'amazon': 'shopping',
      'flipkart': 'shopping',
      'myntra': 'shopping',
      'hospital': 'health',
      'pharmacy': 'health',
      'medplus': 'health',
      'school': 'education',
      'college': 'education',
      'emi': 'emi',
      'loan': 'emi',
      'insurance': 'insurance',
      'salary': 'salary',
      'atm': 'cash',
    };

    for (final entry in keywordMap.entries) {
      if (merchantLower.contains(entry.key)) {
        final hint = entry.value;
        final match = cats
            .where((c) => c.name.toLowerCase().contains(hint))
            .toList();
        if (match.isNotEmpty) return match.first.id;
      }
    }
    return null;
  }
}
