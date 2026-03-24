import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/products/domain/entities/product.dart';

class InventoryPdfUtils {
  static Future<void> generateAndDownloadInventoryReport({
    required List<Product> products,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

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
                      'Inventory Status Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2563EB), // App primary color
                      ),
                    ),
                    pw.Text(
                      'Total Products: ${products.length}',
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
            pw.SizedBox(height: 24),

            // Products Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey50),
                  children: [
                    _buildTableCell('Product Name', isHeader: true),
                    _buildTableCell('Category', isHeader: true),
                    _buildTableCell('Price', isHeader: true),
                    _buildTableCell('Stock Level', isHeader: true),
                  ],
                ),
                ...products.map((product) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(product.name),
                      _buildTableCell(product.category),
                      _buildTableCell('Rs ${product.sellingPrice.toStringAsFixed(0)}'),
                      _buildTableCell(
                        '${product.stockQuantity} ${product.unit}',
                        textColor: product.isLowStock ? PdfColors.red900 : PdfColors.black,
                        isBold: product.isLowStock,
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.Spacer(),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                'This report provides current stock status for procurement planning.',
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
      name: 'Inventory_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Padding _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor textColor = PdfColors.black,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 11 : 10,
          color: textColor,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
}
