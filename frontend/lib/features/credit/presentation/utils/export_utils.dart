import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:frontend/features/credit/domain/entities/customer.dart';

class CreditExportUtils {
  static Future<void> exportActiveCreditsPdf(List<Customer> customers) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Active Credit Customers', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Name', 'Phone', 'Credit Limit (Rs)', 'Outstanding (Rs)'],
                  ...customers.map((c) => [
                        c.name,
                        c.phone,
                        c.creditLimit.toStringAsFixed(2),
                        c.totalOutstanding.toStringAsFixed(2),
                      ]),
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'active_credit_customers.pdf');
  }
}
