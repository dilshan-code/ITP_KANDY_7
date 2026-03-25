import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/suppliers/domain/entities/supplier.dart';
import 'package:frontend/features/suppliers/domain/entities/purchase.dart';

class SupplierExportUtils {
  static Future<void> exportSuppliersPdf(List<Supplier> suppliers) async {
    final pdf = pw.Document();
    
    final totalPayable = suppliers.fold(0.0, (sum, s) => sum + s.totalPayable);

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
                      'SUPPLIER DIRECTORY',
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
                    pw.Text('Total Payable', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(
                      'Rs ${totalPayable.toStringAsFixed(0)}',
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
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildCell('Supplier Name', isHeader: true),
                    _buildCell('Phone', isHeader: true),
                    _buildCell('Email', isHeader: true),
                    _buildCell('Payable (Rs)', isHeader: true),
                  ],
                ),
                ...suppliers.map((s) => pw.TableRow(
                      children: [
                        _buildCell(s.name),
                        _buildCell(s.phone),
                        _buildCell(s.email),
                        _buildCell(s.totalPayable.toStringAsFixed(0), align: pw.TextAlign.right, color: s.totalPayable > 0 ? PdfColors.red700 : null),
                      ],
                    )),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'suppliers_list_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<void> exportPurchasesPdf(List<Purchase> purchases) async {
    final pdf = pw.Document();
    
    final totalPurchases = purchases.fold(0.0, (sum, p) => sum + p.totalAmount);

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
                      'PURCHASE RECORDS',
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
                    pw.Text('Total volume', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(
                      'Rs ${totalPurchases.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
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
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildCell('Date', isHeader: true),
                    _buildCell('Invoice', isHeader: true),
                    _buildCell('Supplier', isHeader: true),
                    _buildCell('Amount (Rs)', isHeader: true),
                  ],
                ),
                ...purchases.map((p) => pw.TableRow(
                      children: [
                        _buildCell(DateFormat('yyyy-MM-dd').format(DateTime.tryParse(p.purchaseDate) ?? DateTime.now())),
                        _buildCell(p.invoiceNumber),
                        _buildCell(p.supplierName),
                        _buildCell(p.totalAmount.toStringAsFixed(0), align: pw.TextAlign.right),
                      ],
                    )),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'purchase_records_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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
