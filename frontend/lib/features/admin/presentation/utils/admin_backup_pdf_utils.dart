import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:frontend/features/auth/domain/entities/owner.dart';

class AdminBackupPdfUtils {
  static Future<void> exportOwnerBackupSnapshot(List<Owner> owners) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    final sortedOwners = [...owners]
      ..sort((a, b) => a.shopName.toLowerCase().compareTo(b.shopName.toLowerCase()));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Database Backup Snapshot',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Generated on ${DateFormat('yyyy-MM-dd hh:mm a').format(now)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              'This backup snapshot contains the current owner registration dataset visible to the admin dashboard.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: const ['Shop', 'Owner', 'Phone', 'Email', 'Status'],
            data: sortedOwners.map((owner) {
              return [
                owner.shopName.isNotEmpty ? owner.shopName : '-',
                owner.name.isNotEmpty ? owner.name : '-',
                owner.phone.isNotEmpty ? owner.phone : '-',
                owner.email.isNotEmpty ? owner.email : '-',
                _statusLabel(owner),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Owner_Backup_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf',
    );
  }

  static String _statusLabel(Owner owner) {
    if (owner.isSuspended || owner.status == 'suspended') return 'Suspended';
    if (owner.status == 'pending') return 'Pending';
    return 'Approved';
  }
}
