import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _loadingCredit = false;
  bool _loadingStock = false;
  bool _loadingPayment = false;

  final DatabaseReference _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://notification-47e11-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  Future<void> _generateCreditReport() async {
    setState(() => _loadingCredit = true);
    try {
      final snap = await _db.child('customers').once();
      final data = snap.snapshot.value as Map<dynamic, dynamic>?;
      final pdf = pw.Document();
      final rows = <List<String>>[
        ['Name', 'Balance (LKR)', 'Due Date', 'Days Overdue', 'Status']
      ];
      if (data != null) {
        final today = DateTime.now();
        for (final entry in data.entries) {
          final c = Map<dynamic, dynamic>.from(entry.value);
          final balance = (c['creditBalance'] ?? 0).toDouble();
          if (balance <= 0) continue;
          final dueDate = DateTime.tryParse(c['dueDate'] ?? '') ?? today;
          final days = today.difference(dueDate).inDays;
          rows.add([
            c['name'] ?? '',
            'LKR ${balance.toStringAsFixed(2)}',
            c['dueDate'] ?? '',
            days > 0 ? '$days days' : 'Not overdue',
            days > 0 ? 'OVERDUE' : 'OK',
          ]);
        }
      }
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.red800,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Credit Overdue Report',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      'Generated: ${DateTime.now().toString().substring(0, 16)}',
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: rows.first,
              data: rows.skip(1).toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 11),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.red800),
              cellStyle: const pw.TextStyle(fontSize: 10),
              rowDecoration:
                  const pw.BoxDecoration(color: PdfColors.red50),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Total overdue customers: ${rows.length - 1}',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ],
        ),
      ));
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      setState(() => _loadingCredit = false);
    }
  }

  Future<void> _generateStockReport() async {
    setState(() => _loadingStock = true);
    try {
      final snap = await _db.child('products').once();
      final data = snap.snapshot.value as Map<dynamic, dynamic>?;
      final pdf = pw.Document();
      final rows = <List<String>>[
        ['Product', 'Stock', 'Unit', 'Threshold', 'Category', 'Status']
      ];
      if (data != null) {
        for (final entry in data.entries) {
          final p = Map<dynamic, dynamic>.from(entry.value);
          final stock = (p['stock'] ?? 0).toInt();
          final threshold = (p['lowStockThreshold'] ?? 0).toInt();
          if (stock > threshold) continue;
          rows.add([
            p['name'] ?? '',
            '$stock',
            p['unit'] ?? '',
            '$threshold',
            p['category'] ?? '',
            stock == 0 ? 'OUT OF STOCK' : 'LOW STOCK',
          ]);
        }
      }
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange800,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Low Stock Report',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      'Generated: ${DateTime.now().toString().substring(0, 16)}',
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: rows.first,
              data: rows.skip(1).toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 11),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.orange800),
              cellStyle: const pw.TextStyle(fontSize: 10),
              rowDecoration:
                  const pw.BoxDecoration(color: PdfColors.orange50),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Total low stock items: ${rows.length - 1}',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ],
        ),
      ));
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      setState(() => _loadingStock = false);
    }
  }

  Future<void> _generatePaymentReport() async {
    setState(() => _loadingPayment = true);
    try {
      final snap = await _db.child('customers').once();
      final data = snap.snapshot.value as Map<dynamic, dynamic>?;
      final pdf = pw.Document();
      final rows = <List<String>>[
        ['Customer', 'Phone', 'Total Paid (LKR)', 'Credit Limit', 'Balance']
      ];
      if (data != null) {
        for (final entry in data.entries) {
          final c = Map<dynamic, dynamic>.from(entry.value);
          final paid = (c['totalPaid'] ?? 0).toDouble();
          if (paid <= 0) continue;
          rows.add([
            c['name'] ?? '',
            c['phone'] ?? '',
            'LKR ${paid.toStringAsFixed(2)}',
            'LKR ${(c['creditLimit'] ?? 0).toStringAsFixed(2)}',
            'LKR ${(c['creditBalance'] ?? 0).toStringAsFixed(2)}',
          ]);
        }
      }
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.green800,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Payment Received Report',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      'Generated: ${DateTime.now().toString().substring(0, 16)}',
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: rows.first,
              data: rows.skip(1).toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 11),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.green800),
              cellStyle: const pw.TextStyle(fontSize: 10),
              rowDecoration:
                  const pw.BoxDecoration(color: PdfColors.green50),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Total customers with payments: ${rows.length - 1}',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ],
        ),
      ));
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      setState(() => _loadingPayment = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Download Reports',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tap a report to generate and download as PDF',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _ReportCard(
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.red,
              title: 'Credit Overdue Report',
              subtitle: 'Customers with outstanding balances',
              isLoading: _loadingCredit,
              onTap: _generateCreditReport,
            ),
            const SizedBox(height: 12),
            _ReportCard(
              icon: Icons.inventory_2,
              iconColor: Colors.orange,
              title: 'Low Stock Report',
              subtitle: 'Products below threshold',
              isLoading: _loadingStock,
              onTap: _generateStockReport,
            ),
            const SizedBox(height: 12),
            _ReportCard(
              icon: Icons.payment,
              iconColor: Colors.green,
              title: 'Payment Received Report',
              subtitle: 'Customers who made payments',
              isLoading: _loadingPayment,
              onTap: _generatePaymentReport,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: iconColor, width: 4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: iconColor),
                  )
                : Icon(Icons.download, color: iconColor, size: 24),
          ],
        ),
      ),
    );
  }
}