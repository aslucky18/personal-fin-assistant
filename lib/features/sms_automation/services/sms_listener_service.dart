import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:another_telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../categories/services/category_service.dart';
import '../../goals/services/goal_service.dart';
import '../../liabilities/services/liability_service.dart';
import '../../accounts/services/account_service.dart';
import '../models/pending_transaction.dart';
import '../services/pending_transaction_service.dart';
import '../services/sms_parser_service.dart';

/// Key stored in SharedPreferences to toggle SMS monitoring on/off
const String kSmsMonitoringEnabledKey = 'sms_monitoring_enabled';

/// Called by another_telephony when an SMS arrives in the BACKGROUND (top-level function).
@pragma('vm:entry-point')
void onBackgroundSmsReceived(SmsMessage message) async {
  // We cannot call Supabase here directly (no Flutter engine),
  // so we store raw SMS in SharedPreferences for processing when app opens.
  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool(kSmsMonitoringEnabledKey) ?? true;
  if (!enabled) return;

  final sender = message.address ?? '';
  final body = message.body ?? '';
  if (!SmsParserService.isBankSender(sender)) return;

  final parsed = SmsParserService.parse(body, sender);
  if (!parsed.isTransactionSms || parsed.amount == null) return;

  // Queue a raw pending entry with minimal info (no DB access in background)
  final id = DateTime.now().millisecondsSinceEpoch.toString();
  final tx = PendingTransaction(
    id: id,
    rawSms: body,
    sender: sender,
    amount: parsed.amount!,
    type: parsed.type,
    accountEndsWith: parsed.accountEndsWith,
    merchant: parsed.merchant,
    timestamp: parsed.timestamp,
  );

  await PendingTransactionService.instance.add(tx);
}

/// Main SMS listener service – initialize once after login.
class SmsListenerService {
  SmsListenerService._();
  static final SmsListenerService instance = SmsListenerService._();

  final Telephony _telephony = Telephony.instance;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Call once after the user is authenticated and on Android only.
  Future<void> initialize() async {
    if (_initialized) return;
    if (!Platform.isAndroid) return;

    await _initNotifications();
    await _requestPermissions();
    _registerForegroundListener();

    _initialized = true;
  }

  // ── Notifications ────────────────────────────────────────────────────────
  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      'sms_transactions',
      'SMS Transactions',
      description: 'Alerts for bank SMS detected transactions',
      importance: Importance.high,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showNotification(PendingTransaction tx) async {
    final symbol = tx.type == 'debit' ? '↓' : '↑';
    await _notifications.show(
      tx.id.hashCode,
      '$symbol ₹${tx.amount.toStringAsFixed(0)} ${tx.type == 'debit' ? 'Debit' : 'Credit'} Detected',
      '${tx.merchant} • Tap to review in Finanalyzer',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sms_transactions',
          'SMS Transactions',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // ── Permissions ──────────────────────────────────────────────────────────
  Future<void> _requestPermissions() async {
    await _telephony.requestPhoneAndSmsPermissions;
  }

  bool _isSmsMonitoringEnabled = true;

  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kSmsMonitoringEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kSmsMonitoringEnabledKey, enabled);
    _isSmsMonitoringEnabled = enabled;
  }

  // ── Foreground listener ──────────────────────────────────────────────────
  void _registerForegroundListener() {
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        if (!_isSmsMonitoringEnabled) return;
        await _processSms(message);
      },
      onBackgroundMessage: onBackgroundSmsReceived,
      listenInBackground: true,
    );
  }

  Future<void> _processSms(SmsMessage message) async {
    final sender = message.address ?? '';
    final body = message.body ?? '';

    if (!SmsParserService.isBankSender(sender)) return;
    final parsed = SmsParserService.parse(body, sender);
    if (!parsed.isTransactionSms || parsed.amount == null) return;

    // Load user data for auto-assignment (only in foreground where Supabase is available)
    String? categoryId, goalId, liabilityId, accountId;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final categories = await CategoryService().getCategories();
        final goals = await GoalService().getGoals();
        final liabilities = await LiabilityService().getLiabilities();
        final accounts = await AccountService().getAccounts();

        final assigned = SmsParserService.autoAssign(
          merchant: parsed.merchant,
          type: parsed.type,
          accountEndsWith: parsed.accountEndsWith,
          categories: categories,
          goals: goals,
          liabilities: liabilities,
          accounts: accounts,
        );
        categoryId = assigned.categoryId;
        goalId = assigned.goalId;
        liabilityId = assigned.liabilityId;
        accountId = assigned.accountId;
      }
    } catch (e) {
      debugPrint('[SmsListener] Auto-assign error: $e');
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final tx = PendingTransaction(
      id: id,
      rawSms: body,
      sender: sender,
      amount: parsed.amount!,
      type: parsed.type,
      accountEndsWith: parsed.accountEndsWith,
      merchant: parsed.merchant,
      timestamp: parsed.timestamp,
      categoryId: categoryId,
      goalId: goalId,
      liabilityId: liabilityId,
      accountId: accountId,
    );

    await PendingTransactionService.instance.add(tx);
    await _showNotification(tx);
  }

  /// Call this when the app is opened to enrich any background-queued raw
  /// pending transactions that are missing auto-assignment fields.
  Future<void> enrichPendingTransactions() async {
    if (!Platform.isAndroid) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final pending = await PendingTransactionService.instance.getAll();
      final unassigned = pending.where((t) => t.categoryId == null).toList();
      if (unassigned.isEmpty) return;

      final categories = await CategoryService().getCategories();
      final goals = await GoalService().getGoals();
      final liabilities = await LiabilityService().getLiabilities();
      final accounts = await AccountService().getAccounts();

      for (final tx in unassigned) {
        final assigned = SmsParserService.autoAssign(
          merchant: tx.merchant,
          type: tx.type,
          accountEndsWith: tx.accountEndsWith,
          categories: categories,
          goals: goals,
          liabilities: liabilities,
          accounts: accounts,
        );
        final enriched = tx.copyWith(
          categoryId: assigned.categoryId,
          goalId: assigned.goalId,
          liabilityId: assigned.liabilityId,
          accountId: assigned.accountId,
        );
        await PendingTransactionService.instance.update(enriched);
      }
    } catch (e) {
      debugPrint('[SmsListener] Enrich error: $e');
    }
  }
}
