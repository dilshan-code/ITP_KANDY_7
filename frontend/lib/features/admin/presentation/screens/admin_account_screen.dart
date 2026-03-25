import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/admin/presentation/providers/admin_provider.dart';
import 'package:frontend/features/admin/presentation/utils/admin_backup_pdf_utils.dart';
import 'package:frontend/features/auth/domain/entities/owner.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';

class AdminAccountScreen extends StatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  DateTime? _lastBackupAt;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Admin Settings',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 32),
            _buildSettingsList(
              context,
              authProvider,
              adminProvider,
              notificationProvider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.indigo.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.admin_panel_settings,
            size: 48,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'System Administrator',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'admin@clickbuy.com',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSettingsList(
    BuildContext context,
    AuthProvider auth,
    AdminProvider adminProvider,
    NotificationProvider notificationProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.security,
            title: 'Security Logs',
            subtitle: 'View recent owner access and account activity',
            onTap: () => _showSecurityLogs(context, adminProvider.owners),
          ),
          _buildSettingsItem(
            icon: Icons.notifications_active_outlined,
            title: 'System Notifications',
            subtitle:
                'Broadcast updates to owners (${notificationProvider.notifications.length} tracked)',
            onTap: () => _showNotificationComposer(context, notificationProvider),
          ),
          _buildSettingsItem(
            icon: Icons.backup_outlined,
            title: 'Database Backup',
            subtitle: _lastBackupAt == null
                ? 'Create a fresh owner backup snapshot'
                : 'Last backup: ${_formatBackupTime(_lastBackupAt!)}',
            onTap: () => _runBackup(context, adminProvider),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out from ClickBuy Admin',
            iconColor: Colors.redAccent,
            onTap: () {
              auth.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.indigo).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? Colors.indigo, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }

  Future<void> _runBackup(
    BuildContext context,
    AdminProvider adminProvider,
  ) async {
    if (adminProvider.owners.isEmpty) {
      SnackBarUtils.showTopSnackBar(
        context,
        'No owner records available to back up yet.',
        isError: true,
      );
      return;
    }

    await AdminBackupPdfUtils.exportOwnerBackupSnapshot(adminProvider.owners);
    if (!mounted) return;

    setState(() => _lastBackupAt = DateTime.now());
    SnackBarUtils.showTopSnackBar(
      context,
      'Database backup snapshot generated successfully.',
    );
  }

  void _showSecurityLogs(BuildContext context, List<Owner> owners) {
    final logs = _buildSecurityLogs(owners);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SecurityLogsSheet(logs: logs),
    );
  }

  List<_SecurityLogItem> _buildSecurityLogs(List<Owner> owners) {
    final logs = <_SecurityLogItem>[];

    for (final owner in owners) {
      final createdAt = DateTime.tryParse(owner.createdAt) ?? DateTime.now();
      logs.add(
        _SecurityLogItem(
          title: 'Registration received',
          description:
              '${owner.shopName.isNotEmpty ? owner.shopName : owner.name} joined the system.',
          timestamp: createdAt,
          color: Colors.blue,
          icon: Icons.person_add_alt_1_rounded,
        ),
      );

      final updatedAt = DateTime.tryParse(owner.createdAt) ?? createdAt;

      if (owner.isSuspended || owner.status == 'suspended') {
        logs.add(
          _SecurityLogItem(
            title: 'Account suspended',
            description:
                '${owner.shopName.isNotEmpty ? owner.shopName : owner.name} is currently blocked from login access.',
            timestamp: updatedAt,
            color: Colors.red,
            icon: Icons.gpp_bad_outlined,
          ),
        );
      } else if (owner.status == 'approved') {
        logs.add(
          _SecurityLogItem(
            title: 'Account approved',
            description:
                '${owner.shopName.isNotEmpty ? owner.shopName : owner.name} has active admin approval.',
            timestamp: updatedAt,
            color: Colors.green,
            icon: Icons.verified_user_outlined,
          ),
        );
      } else {
        logs.add(
          _SecurityLogItem(
            title: 'Pending review',
            description:
                '${owner.shopName.isNotEmpty ? owner.shopName : owner.name} is waiting for admin action.',
            timestamp: updatedAt,
            color: Colors.orange,
            icon: Icons.hourglass_top_rounded,
          ),
        );
      }
    }

    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  void _showNotificationComposer(
    BuildContext context,
    NotificationProvider notificationProvider,
  ) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'info';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD5D9E2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Broadcast system notification',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Send a message that owners can see in their notification feed.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          items: const [
                            DropdownMenuItem(
                              value: 'info',
                              child: Text('Info'),
                            ),
                            DropdownMenuItem(
                              value: 'warning',
                              child: Text('Warning'),
                            ),
                            DropdownMenuItem(
                              value: 'alert',
                              child: Text('Alert'),
                            ),
                            DropdownMenuItem(
                              value: 'success',
                              child: Text('Success'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() => selectedType = value);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Notification type',
                            filled: true,
                            fillColor: Color(0xFFF8FAFC),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            filled: true,
                            fillColor: Color(0xFFF8FAFC),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: messageController,
                          minLines: 4,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Message',
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Color(0xFFF8FAFC),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () async {
                              final title = titleController.text.trim();
                              final message = messageController.text.trim();

                              if (title.isEmpty || message.isEmpty) {
                                SnackBarUtils.showTopSnackBar(
                                  context,
                                  'Title and message are required.',
                                  isError: true,
                                );
                                return;
                              }

                              final previousError = notificationProvider.error;

                              await notificationProvider.createNotification(
                                type: selectedType,
                                title: title,
                                message: message,
                              );

                              if (!context.mounted) return;
                              Navigator.pop(sheetContext);
                              final hasFreshError =
                                  notificationProvider.error != null &&
                                  notificationProvider.error != previousError;
                              SnackBarUtils.showTopSnackBar(
                                context,
                                hasFreshError
                                    ? notificationProvider.error!
                                    : 'System notification sent successfully.',
                                isError: hasFreshError,
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Send Notification'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatBackupTime(DateTime value) {
    final now = DateTime.now();
    final difference = now.difference(value);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }
}

class _SecurityLogsSheet extends StatelessWidget {
  final List<_SecurityLogItem> logs;

  const _SecurityLogsSheet({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5D9E2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Security Logs',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Recent account and registration events visible from the admin dashboard.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 420,
                child: logs.isEmpty
                    ? const Center(
                        child: Text('No security events available yet.'),
                      )
                    : ListView.separated(
                        itemCount: logs.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: log.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(log.icon, color: log.color),
                            ),
                            title: Text(
                              log.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(log.description),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(log.timestamp),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime time) {
    return '${time.year.toString().padLeft(4, '0')}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _SecurityLogItem {
  final String title;
  final String description;
  final DateTime timestamp;
  final Color color;
  final IconData icon;

  const _SecurityLogItem({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.color,
    required this.icon,
  });
}
