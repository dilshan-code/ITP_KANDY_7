import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/notifications/presentation/screens/notification_screen.dart';

class NotificationIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const NotificationIcon({super.key, this.color, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ).then((_) {
              if (context.mounted) notificationProvider.fetchNotifications();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: color ?? AppColors.textMedium,
                  size: size,
                ),
                if (notificationProvider.unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Center(
                        child: Text(
                          notificationProvider.unreadCount > 9
                              ? '9+'
                              : notificationProvider.unreadCount.toString(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
