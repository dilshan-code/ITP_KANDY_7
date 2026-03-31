import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/credit/domain/entities/customer.dart';

class CreditExportUtils {
  static Future<void> exportActiveCreditsPdf(List<Customer> customers) async {
    final pdf = pw.Document();
    
    final totalOutstanding = customers.fold(0.0, (sum, item) => sum + item.totalOutstanding);

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
                      'ACTIVE CREDITORS REPORT',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2563EB),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Total Outstanding', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(
                      'Rs ${totalOutstanding.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildCell('Customer Name', isHeader: true),
                    _buildCell('Phone', isHeader: true),
                    _buildCell('Limit (Rs)', isHeader: true),
                    _buildCell('Due Amount (Rs)', isHeader: true),
                  ],
                ),
                // Data Rows
                ...customers.map((c) => pw.TableRow(
                      children: [
                        _buildCell(c.name),
                        _buildCell(c.phone),
                        _buildCell(c.creditLimit.toStringAsFixed(0), align: pw.TextAlign.right),
                        _buildCell(c.totalOutstanding.toStringAsFixed(0), 
                                  align: pw.TextAlign.right, 
                                  color: PdfColors.red700),
                      ],
                    )),
              ],
            ),
            
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Record Count: ${customers.length}', 
                       style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'active_creditors_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<void> exportSettledCreditsPdf(List<Customer> customers) async {
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
                      'SETTLED CUSTOMERS REPORT',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF059669), // Emerald/Green color
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Status', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(
                      'ALL PAID / CLEAR',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildCell('Customer Name', isHeader: true),
                    _buildCell('Phone', isHeader: true),
                    _buildCell('Limit (Rs)', isHeader: true),
                    _buildCell('Status', isHeader: true),
                  ],
                ),
                // Data Rows
                ...customers.map((c) => pw.TableRow(
                      children: [
                        _buildCell(c.name),
                        _buildCell(c.phone),
                        _buildCell(c.creditLimit.toStringAsFixed(0), align: pw.TextAlign.right),
                        _buildCell('Paid', 
                                  align: pw.TextAlign.center, 
                                  color: PdfColors.green700),
                      ],
                    )),
              ],
            ),
            
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Record Count: ${customers.length}', 
                       style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'settled_customers_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Padding _buildCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left, PdfColor? color}) {

    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 11 : 10,
          color: color,
        ),
        textAlign: align,
      ),
    );
  }
}
