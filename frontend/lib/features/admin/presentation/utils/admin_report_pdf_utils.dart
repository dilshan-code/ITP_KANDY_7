import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:frontend/features/auth/domain/entities/owner.dart';

class AdminReportPdfUtils {
  static Future<void> exportOwnerRegistrationReport(
    List<Owner> owners,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final total = owners.length;
    final approved = owners
        .where((owner) => owner.status == 'approved' && owner.isSuspended == false)
        .length;
    final suspended = owners
        .where((owner) => owner.status == 'suspended' || owner.isSuspended)
        .length;
    final pending = owners
        .where((owner) => owner.status == 'pending' && owner.isSuspended == false)
        .length;

    final sortedOwners = [...owners]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: PdfColors.green900,
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Client Registration Report',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Generated on ${DateFormat('yyyy-MM-dd hh:mm a').format(now)}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetricCard('Registered', total.toString(), PdfColors.blue900),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildMetricCard('Approved', approved.toString(), PdfColors.green800),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildMetricCard('Suspended', suspended.toString(), PdfColors.red800),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildMetricCard('Pending', pending.toString(), PdfColors.amber800),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'This report gives a practical snapshot of current partner registrations for admin review and follow-up.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Registration Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: const ['Shop', 'Owner', 'Phone', 'Email', 'Status'],
            data: sortedOwners.map((owner) {
              return [
                owner.shopName.isNotEmpty ? owner.shopName : '-',
                owner.name.isNotEmpty ? owner.name : '-',
                owner.phone.isNotEmpty ? owner.phone : '-',
                owner.email.isNotEmpty ? owner.email : '-',
                _ownerStatus(owner),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Divider(color: PdfColors.grey400),
          pw.Text(
            'Generated automatically by the ClickBuy admin dashboard.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Client_Registration_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildMetricCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static String _ownerStatus(Owner owner) {
    if (owner.status == 'suspended' || owner.isSuspended) {
      return 'Suspended';
    }
    if (owner.status == 'pending') {
      return 'Pending';
    }
    return 'Approved';
  }
}
