import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/sms_listener_service.dart';
import '../services/pending_transaction_service.dart';
import '../services/sms_parser_service.dart';

class SmsSettingsScreen extends StatefulWidget {
  const SmsSettingsScreen({super.key});

  @override
  State<SmsSettingsScreen> createState() => _SmsSettingsScreenState();
}

class _SmsSettingsScreenState extends State<SmsSettingsScreen>
    with WidgetsBindingObserver {
  bool _smsEnabled = true;
  bool _hasSmsPermission = false;
  bool _hasNotifPermission = false;
  int _pendingCount = 0;
  final List<String> _senderWhitelist = List.from(kBankSenderIds);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await SmsListenerService.instance.isEnabled;
    final smsPerm = await Permission.sms.isGranted;
    final notifPerm = Platform.isAndroid
        ? await Permission.notification.isGranted
        : true;
    final count = await PendingTransactionService.instance.pendingCount();
    if (mounted) {
      setState(() {
        _smsEnabled = enabled;
        _hasSmsPermission = smsPerm;
        _hasNotifPermission = notifPerm;
        _pendingCount = count;
      });
    }
  }

  Future<void> _requestSmsPermission() async {
    final result = await Permission.sms.request();
    if (result.isPermanentlyDenied && mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'SMS permission was permanently denied. Please enable it from app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
    await _loadState();
  }

  Future<void> _requestNotifPermission() async {
    await Permission.notification.request();
    await _loadState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Automation Settings'),
        centerTitle: true,
      ),
      body: Platform.isAndroid
          ? _buildAndroidBody(theme, cs)
          : _buildUnsupportedBody(theme),
    );
  }

  Widget _buildUnsupportedBody(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sms_failed_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Only Available on Android', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'iOS does not allow apps to read SMS messages.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidBody(ThemeData theme, ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Status Card ────────────────────────────────────────────────────
        _buildStatusCard(theme, cs),
        const SizedBox(height: 16),

        // ── Main toggle ───────────────────────────────────────────────────
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
          ),
          child: SwitchListTile(
            title: const Text(
              'Enable SMS Monitoring',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Automatically detect transactions from bank SMS',
            ),
            value: _smsEnabled,
            onChanged: (val) async {
              await SmsListenerService.instance.setEnabled(val);
              setState(() => _smsEnabled = val);
            },
          ),
        ),
        const SizedBox(height: 16),

        // ── Permissions ───────────────────────────────────────────────────
        Text('Permissions', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _permissionTile(
          icon: Icons.message_outlined,
          label: 'SMS Access',
          description: 'Read and receive SMS messages',
          granted: _hasSmsPermission,
          onRequest: _requestSmsPermission,
          cs: cs,
        ),
        const SizedBox(height: 8),
        _permissionTile(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          description: 'Show alerts when transactions detected',
          granted: _hasNotifPermission,
          onRequest: _requestNotifPermission,
          cs: cs,
        ),
        const SizedBox(height: 16),

        // ── Queue info ────────────────────────────────────────────────────
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
          ),
          child: ListTile(
            leading: Badge(
              label: Text('$_pendingCount'),
              isLabelVisible: _pendingCount > 0,
              child: const Icon(Icons.pending_actions_outlined),
            ),
            title: const Text('Pending Transactions'),
            subtitle: Text(
              '$_pendingCount transaction${_pendingCount == 1 ? '' : 's'} awaiting review',
            ),
            trailing: _pendingCount > 0
                ? TextButton(
                    onPressed: () async {
                      await PendingTransactionService.instance.clearAll();
                      await _loadState();
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 24),

        // ── Bank Senders ──────────────────────────────────────────────────
        Text('Recognized Bank Sender IDs', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Messages from these senders will be monitored for transactions.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _senderWhitelist
              .map(
                (id) => Chip(
                  label: Text(id, style: const TextStyle(fontSize: 12)),
                  backgroundColor: cs.surfaceContainerHighest,
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),

        // ── How it works ──────────────────────────────────────────────────
        _buildHowItWorks(theme, cs),
      ],
    );
  }

  Widget _buildStatusCard(ThemeData theme, ColorScheme cs) {
    final allGood = _smsEnabled && _hasSmsPermission;
    final statusColor = allGood
        ? Colors.green.shade600
        : Colors.orange.shade700;
    final statusText = allGood ? 'SMS Automation is Active' : 'Action Required';
    final statusIcon = allGood ? Icons.check_circle : Icons.warning_amber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  allGood
                      ? 'Bank SMS messages are being monitored'
                      : 'Enable SMS monitoring and grant permissions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionTile({
    required IconData icon,
    required String label,
    required String description,
    required bool granted,
    required VoidCallback onRequest,
    required ColorScheme cs,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: granted ? Colors.green : cs.onSurfaceVariant,
        ),
        title: Text(label),
        subtitle: Text(description),
        trailing: granted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : TextButton(onPressed: onRequest, child: const Text('Grant')),
      ),
    );
  }

  Widget _buildHowItWorks(ThemeData theme, ColorScheme cs) {
    final steps = [
      (
        'SMS Received',
        'App detects incoming bank or payment SMS',
        Icons.sms_outlined,
      ),
      (
        'Auto Parse',
        'Amount, merchant, and account are extracted',
        Icons.auto_fix_high_outlined,
      ),
      (
        'Auto Assign',
        'Category, goal & debt assigned by smart keyword matching',
        Icons.category_outlined,
      ),
      (
        'Review',
        'You see a pending transaction to approve or reject',
        Icons.checklist_outlined,
      ),
      (
        'Record Created',
        'Approved transactions saved to your finance tracker',
        Icons.done_all_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How it Works', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((entry) {
          final i = entry.key;
          final (title, desc, icon) = entry.value;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: cs.primary),
                  ),
                  if (i < steps.length - 1)
                    Container(width: 2, height: 24, color: cs.outlineVariant),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        desc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
