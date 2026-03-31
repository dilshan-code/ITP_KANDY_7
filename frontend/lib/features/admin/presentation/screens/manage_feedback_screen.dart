import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/account/presentation/providers/feedback_provider.dart';
import 'package:frontend/features/account/domain/entities/feedback.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class ManageFeedbackScreen extends StatefulWidget {
  const ManageFeedbackScreen({super.key});

  @override
  State<ManageFeedbackScreen> createState() => _ManageFeedbackScreenState();
}

class _ManageFeedbackScreenState extends State<ManageFeedbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedbackProvider>().fetchAllFeedback();
    });
  }

  String _getDateCategory(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final feedbackDate = DateTime(date.year, date.month, date.day);

    if (feedbackDate == today) return 'Today';
    if (feedbackDate == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  Map<String, List<UserFeedback>> _groupFeedback(List<UserFeedback> feedbacks) {
    final Map<String, List<UserFeedback>> grouped = {};
    for (var feedback in feedbacks) {
      final category = _getDateCategory(feedback.createdAt);
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(feedback);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final feedbackProvider = context.watch<FeedbackProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('User Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: feedbackProvider.isLoading && feedbackProvider.feedbacks.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : feedbackProvider.feedbacks.isEmpty
              ? _buildEmptyState()
              : _buildFeedbackList(feedbackProvider),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feedback_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No feedback received yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackList(FeedbackProvider provider) {
    final grouped = _groupFeedback(provider.feedbacks);
    final sortedKeys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () => provider.fetchAllFeedback(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final dateKey = sortedKeys[index];
          final feedbacks = grouped[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...feedbacks.map((f) => _buildFeedbackCard(f, provider)),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeedbackCard(UserFeedback feedback, FeedbackProvider provider) {
    Color categoryColor;
    IconData categoryIcon;

    switch (feedback.category.toLowerCase()) {
      case 'error':
        categoryColor = Colors.red;
        categoryIcon = Icons.error_outline;
        break;
      case 'improvement':
        categoryColor = Colors.blue;
        categoryIcon = Icons.lightbulb_outline;
        break;
      default:
        categoryColor = Colors.green;
        categoryIcon = Icons.chat_bubble_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 20),
          ),
          title: Text(
            feedback.ownerName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            feedback.category,
            style: TextStyle(
              color: categoryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Text(
            DateFormat('h:mm a').format(feedback.createdAt),
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                feedback.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _confirmDelete(feedback, provider),
                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                  label: const Text('Delete', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(UserFeedback feedback, FeedbackProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteFeedback(feedback.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
