import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/account/presentation/providers/feedback_provider.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';


class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  String _selectedCategory = 'Feedback';
  final List<String> _categories = ['Feedback', 'Error', 'Improvement'];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Image/Icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'How can we help you?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Search for topics or contact our support team',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Contact Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Us',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.chat_outlined,
                            title: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: () {
                              // Link to WhatsApp
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            color: const Color(0xFFEA4335),
                            onTap: () {
                              // Link to Email
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // FAQ Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frequent Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFAQItem(
                      'How to add a new product?',
                      'Go to the Products tab and click on the "+" button in the top right corner.',
                    ),
                    _buildFAQItem(
                      'Can I manage multiple shops?',
                      'Currently, ClickBuy supports one shop per account for focused management.',
                    ),
                    _buildFAQItem(
                      'How do credit limits work?',
                      'You can set a credit limit for each customer. The system will alert you if they exceed it.',
                    ),
                    _buildFAQItem(
                      'Is my data backed up?',
                      'Yes, all your data is automatically synced to our secure cloud database.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Feedback Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share your thoughts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Have an idea or found a bug? Let us know!',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: _categories.map((category) {
                              final isSelected = _selectedCategory == category;
                              return ChoiceChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedCategory = category);
                                  }
                                },
                                selectedColor: AppColors.primary.withValues(alpha: 0.1),
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textMedium,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : Colors.grey[200]!,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Message',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _feedbackController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Describe your feedback or improvement idea...',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: Consumer<FeedbackProvider>(
                              builder: (context, feedbackProvider, _) {
                                return ElevatedButton(
                                  onPressed: feedbackProvider.isLoading
                                      ? null
                                      : () async {
                                          if (_feedbackController.text.trim().isEmpty) {
                                            SnackBarUtils.showSnackBar(
                                              context,
                                              'Please enter a message',
                                              isError: true,
                                            );
                                            return;
                                          }
                                          
                                          final success = await feedbackProvider.submitFeedback(
                                            _selectedCategory,
                                            _feedbackController.text.trim(),
                                          );

                                          if (success && context.mounted) {
                                            _feedbackController.clear();
                                            SnackBarUtils.showSnackBar(
                                              context,
                                              'Thank you for your feedback!',
                                            );
                                            FocusScope.of(context).unfocus();
                                          } else if (context.mounted) {
                                            SnackBarUtils.showSnackBar(
                                              context,
                                              feedbackProvider.error ?? 'Failed to submit',
                                              isError: true,
                                            );
                                          }
                                        },

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: feedbackProvider.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Submit Feedback',
                                          style: TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
