
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/credit/domain/entities/customer.dart';

class CreditPdfUtils {
  static Future<void> generateAndDownloadStatement({
    required Customer customer,
    required List<dynamic> history,
  }) async {
    final pdf = pw.Document();

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
                      'CREDIT STATEMENT',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2563EB),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.now()),
                      style: const pw.TextStyle(color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Outstanding Balance',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Rs ${customer.totalOutstanding.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 24),

            // Customer Info
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CUSTOMER DETAILS',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text(customer.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text(customer.phone, style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('CREDIT SUMMARY',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      _buildInfoRow('Credit Limit', 'Rs ${customer.creditLimit.toStringAsFixed(0)}'),
                      _buildInfoRow('Status', customer.status.toUpperCase()),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // History Table
            pw.Text('TRANSACTION HISTORY',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell('Date', isHeader: true),
                    _buildTableCell('Description', isHeader: true),
                    _buildTableCell('Type', isHeader: true),
                    _buildTableCell('Amount', isHeader: true),
                  ],
                ),
                // Data
                ...history.map((item) {
                  final String dateStr = item is Map ? item['createdAt'] : item.createdAt;
                  final DateTime date = DateTime.parse(dateStr).toLocal();
                  final String title = item is Map ? (item['customerName'] ?? 'Sale') : item.title;
                  final String type = item is Map ? 'SALE' : (item.type as String).toUpperCase();
                  final double amount = (item is Map ? item['totalAmount'] : item.amount).toDouble();
                  
                  final bool isCredit = type == 'SALE' || type == 'CREDIT';

                  return pw.TableRow(
                    children: [
                      _buildTableCell(DateFormat('dd/MM/yy').format(date)),
                      _buildTableCell(type == 'SALE' ? 'Invoice #${(item is Map ? item['id'] : '').substring(0, 5)}' : title),
                      _buildTableCell(type),
                      _buildTableCell(
                        'Rs ${amount.toStringAsFixed(0)}',
                        color: isCredit ? PdfColors.red700 : PdfColors.green700,
                      ),
                    ],
                  );
                }),
              ],
            ),
            
            pw.SizedBox(height: 40),
            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'This is a computer-generated statement.',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Statement_${customer.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Padding _buildTableCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 10 : 9,
          color: color,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('$label: ', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
