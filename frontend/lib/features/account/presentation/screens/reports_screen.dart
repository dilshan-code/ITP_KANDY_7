import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/account/presentation/utils/report_pdf_utils.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.get('/reports');
      setState(() {
        _reportData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('Exception:') 
            ? e.toString().substring(e.toString().indexOf('Exception:') + 10).trim()
            : 'Error connecting to server';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'Rs. ',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Management Reports',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Download PDF',
            onPressed: _reportData == null || _isLoading
                ? null
                : () => ReportPdfUtils.generateAndDownloadReport(
                      reportData: _reportData!,
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReportData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                  TextButton(
                    onPressed: _fetchReportData,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : _reportData == null
          ? const Center(child: Text('No data available'))
          : RefreshIndicator(
              onRefresh: _fetchReportData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Financial Summary'),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildSummaryCard(
                          'Total Revenue',
                          currencyFormat.format(
                            _reportData!['summary']['totalRevenue'],
                          ),
                          Icons.payments_outlined,
                          AppColors.primary,
                        ),
                        _buildSummaryCard(
                          'Estimated Profit',
                          currencyFormat.format(
                            _reportData!['summary']['totalProfit'],
                          ),
                          Icons.trending_up,
                          AppColors.accentGreen,
                        ),
                        _buildSummaryCard(
                          'Credit Outstanding',
                          currencyFormat.format(
                            _reportData!['summary']['totalCreditOutstanding'],
                          ),
                          Icons.account_balance_wallet_outlined,
                          Colors.orange,
                        ),
                        _buildSummaryCard(
                          'Total Purchases',
                          currencyFormat.format(
                            _reportData!['summary']['totalPurchases'],
                          ),
                          Icons.shopping_bag_outlined,
                          Colors.blue,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Inventory Health'),
                    const SizedBox(height: 12),
                    Container(
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
                          _buildInventoryRow(
                            'Total Stock Value',
                            currencyFormat.format(
                              _reportData!['inventory']['totalValue'],
                            ),
                            Icons.inventory_2_outlined,
                            AppColors.primary,
                          ),
                          const Divider(height: 24),
                          _buildInventoryRow(
                            'Items in Stock',
                            '${_reportData!['inventory']['itemCount']} units',
                            Icons.category_outlined,
                            Colors.purple,
                          ),
                          const Divider(height: 24),
                          _buildInventoryRow(
                            'Low Stock Alerts',
                            '${_reportData!['inventory']['lowStockCount']} items',
                            Icons.warning_amber_rounded,
                            _reportData!['inventory']['lowStockCount'] > 0
                                ? AppColors.error
                                : AppColors.accentGreen,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader('Top Selling Products'),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: (_reportData!['topProducts'] as List).length,
                      itemBuilder: (context, index) {
                        final product = _reportData!['topProducts'][index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
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
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.accentGreen,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              product['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text('${product['quantity']} units sold'),
                            trailing: Text(
                              currencyFormat.format(product['revenue']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if ((_reportData!['topProducts'] as List).isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No sales data available yet',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
