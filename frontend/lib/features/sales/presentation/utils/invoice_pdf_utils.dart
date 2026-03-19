
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class InvoicePdfUtils {
  static Future<void> generateAndDownloadInvoice({
    required Map<String, dynamic> saleDetails,
  }) async {
    final pdf = pw.Document();

    final items = saleDetails['items'] as List<dynamic>? ?? [];
    final totalAmount = (saleDetails['totalAmount'] ?? 0.0).toDouble();
    final paymentMethod = saleDetails['paymentMethod'] ?? 'cash';
    final customerName = saleDetails['customerName'] ?? 'Walk-in Customer';
    final date =
        DateTime.tryParse(saleDetails['createdAt'] ?? '') ?? DateTime.now();
    final invoiceId = saleDetails['id']?.toString().toUpperCase() ?? 'N/A';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          '#$invoiceId',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green100,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        paymentMethod.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.green900,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 32),

                // Details
                _buildPdfDetailRow(
                  'Date',
                  DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                ),
                pw.SizedBox(height: 8),
                _buildPdfDetailRow('Customer', customerName),
                pw.SizedBox(height: 16),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 16),

                // Items Table
                pw.Text(
                  'ITEMS',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey200,
                    width: 0.5,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey100,
                      ),
                      children: [
                        _buildTableCell('Item Description', isHeader: true),
                        _buildTableCell('Qty', isHeader: true),
                        _buildTableCell('Price', isHeader: true),
                        _buildTableCell('Total', isHeader: true),
                      ],
                    ),
                    // Table Body
                    ...items.map((item) {
                      final price = (item['price'] ?? 0.0).toDouble();
                      final qty = item['quantity'] ?? 1;
                      return pw.TableRow(
                        children: [
                          _buildTableCell(item['name'] ?? 'Unknown Item'),
                          _buildTableCell(qty.toString()),
                          _buildTableCell('Rs ${price.toStringAsFixed(0)}'),
                          _buildTableCell(
                            'Rs ${(price * qty).toStringAsFixed(0)}',
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 32),

                // Footer / Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'TOTAL AMOUNT',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Rs ${totalAmount.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_$invoiceId.pdf',
    );
  }

  static pw.Padding _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 11,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
