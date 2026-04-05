import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/sales/presentation/utils/invoice_pdf_utils.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> saleDetails;

  const PaymentSuccessScreen({super.key, required this.saleDetails});

  @override
  Widget build(BuildContext context) {
    final totalAmount = (saleDetails['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final invoiceId = (saleDetails['id'] ?? saleDetails['_id'])?.toString() ?? 'N/A';
    final paymentMethod = saleDetails['paymentMethod']?.toString() ?? 'cash';
    final itemsCount = (saleDetails['items'] as List?)?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      
                      // Animated Success Icon (Simulated with scaling)
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween<double>(begin: 0, end: 1),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Success Message
                      const Text(
                        'Payment Successful',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Your transaction was completed successfully',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const Spacer(flex: 2),
                      
                      // Transaction Details Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                             _buildDetailRow(
                              'Invoice ID', 
                              '#${invoiceId.toUpperCase()}',
                              isBold: true,
                              valueColor: AppColors.primary,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1, color: AppColors.divider),
                            ),
                            _buildDetailRow('Total Amount', 'Rs. ${totalAmount.toStringAsFixed(0)}'),
                            const SizedBox(height: 16),
                            _buildDetailRow('Payment Method', paymentMethod.toUpperCase()),
                            const SizedBox(height: 16),
                            _buildDetailRow('Total Items', itemsCount.toString()),
                          ],
                        ),
                      ),
                      
                      const Spacer(flex: 3),
                      
                      // Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Back to Home',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: () => InvoicePdfUtils.generateAndDownloadInvoice(
                                  saleDetails: saleDetails,
                                ),
                                icon: const Icon(Icons.download_rounded, color: Colors.white),
                                label: const Text(
                                  'Download Receipt',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: () => InvoicePdfUtils.shareInvoice(
                                  saleDetails: saleDetails,
                                ),
                                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                                label: const Text(
                                  'Share Receipt',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label, 
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMedium,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textDark,
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
