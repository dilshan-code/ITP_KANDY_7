import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/auth/domain/entities/owner.dart';

class OwnerPdfUtils {
  static Future<void> generateOwnerListPdf({
    required List<Owner> owners,
    String? filterName,
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
                      'Store Owner Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF163D35), // Theme dark green
                      ),
                    ),
                    pw.Text(
                      'Generated on: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                if (filterName != null && filterName != 'all')
                   pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'Filter: ${filterName.toUpperCase()}',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5), // Shop Name
                1: const pw.FlexColumnWidth(2),   // Owner Name
                2: const pw.FlexColumnWidth(2),   // Contact
                3: const pw.FlexColumnWidth(1),   // Status
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildCell('Shop Name', isHeader: true),
                    _buildCell('Owner', isHeader: true),
                    _buildCell('Contact info', isHeader: true),
                    _buildCell('Status', isHeader: true),
                  ],
                ),
                // Data Rows
                ...owners.map((owner) {
                  final isSuspended = owner.isSuspended || owner.status == 'suspended';
                  return pw.TableRow(
                    children: [
                      _buildCell(owner.shopName.isNotEmpty ? owner.shopName : 'N/A'),
                      _buildCell(owner.name.isNotEmpty ? owner.name : 'N/A'),
                      _buildCell('${owner.phone}\n${owner.email}'),
                      _buildCell(
                        isSuspended ? 'Suspended' : 'Active',
                        color: isSuspended ? PdfColors.red : PdfColors.green,
                      ),
                    ],
                  );
                }),
              ],
            ),

            // Summary
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total Records: ${owners.length}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Store_Owner_List_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Padding _buildCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 10 : 9,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}
