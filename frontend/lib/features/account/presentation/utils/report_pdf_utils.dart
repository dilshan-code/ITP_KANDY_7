import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReportPdfUtils {
  static Future<void> generateAndDownloadReport({
    required Map<String, dynamic> reportData,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    final summary = reportData['summary'] ?? {};
    final inventory = reportData['inventory'] ?? {};
    final topProducts = (reportData['topProducts'] as List?) ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Management Report',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'Confidence Level: High (Real-time Cloud Data)',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date Generated:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(dateFormat.format(now), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // Financial Summary Section
            _buildSectionHeader('FINANCIAL SUMMARY'),
            pw.SizedBox(height: 16),
            pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 0.25,
              children: [
                _buildSummaryStat('Total Revenue', currencyFormat.format(summary['totalRevenue'] ?? 0)),
                _buildSummaryStat('Estimated Profit', currencyFormat.format(summary['totalProfit'] ?? 0)),
                _buildSummaryStat('Credit Outstanding', currencyFormat.format(summary['totalCreditOutstanding'] ?? 0)),
                _buildSummaryStat('Total Purchases', currencyFormat.format(summary['totalPurchases'] ?? 0)),
              ],
            ),
            pw.SizedBox(height: 32),

            // Inventory Health Section
            _buildSectionHeader('INVENTORY HEALTH'),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              children: [
                _buildTableRow('Total Stock Value', currencyFormat.format(inventory['totalValue'] ?? 0)),
                _buildTableRow('Total Items in Stock', '${inventory['itemCount'] ?? 0} units'),
                _buildTableRow('Low Stock Alerts', '${inventory['lowStockCount'] ?? 0} items'),
              ],
            ),
            pw.SizedBox(height: 32),

            // Top Selling Products Section
            if (topProducts.isNotEmpty) ...[
              _buildSectionHeader('TOP SELLING PRODUCTS'),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildTableCell('#', isHeader: true),
                      _buildTableCell('Product Name', isHeader: true),
                      _buildTableCell('Qty Sold', isHeader: true),
                      _buildTableCell('Revenue', isHeader: true),
                    ],
                  ),
                  ...topProducts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;
                    return pw.TableRow(
                      children: [
                        _buildTableCell((index + 1).toString()),
                        _buildTableCell(product['name'] ?? 'Unknown'),
                        _buildTableCell(product['quantity'].toString()),
                        _buildTableCell(currencyFormat.format(product['revenue'] ?? 0)),
                      ],
                    );
                  }),
                ],
              ),
            ],

            pw.Spacer(),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                'This report is generated automatically by ClickBuy System.',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Management_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: PdfColors.blue900, width: 4)),
        color: PdfColors.grey100,
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
      ),
    );
  }

  static pw.Widget _buildSummaryStat(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ],
      ),
    );
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  static pw.Padding _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 10 : 9,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
}
