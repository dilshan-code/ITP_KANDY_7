import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/suppliers/domain/entities/purchase.dart';

void main() {
  group('Purchase Entity', () {
    test('should parse notes from JSON', () {
      final json = {
        'id': '1',
        'supplierId': 's1',
        'supplierName': 'Supplier 1',
        'invoiceNumber': 'INV-001',
        'purchaseDate': '2023-10-01',
        'items': [],
        'subtotal': 100.0,
        'tax': 10.0,
        'totalAmount': 110.0,
        'amountPaid': 110.0,
        'remaining': 0.0,
        'status': 'paid',
        'notes': 'Test notes',
        'createdAt': '2023-10-01T00:00:00Z',
      };

      final purchase = Purchase.fromJson(json);

      expect(purchase.notes, 'Test notes');
    });

    test('should convert notes to JSON', () {
      final purchase = Purchase(
        id: '1',
        supplierId: 's1',
        supplierName: 'Supplier 1',
        notes: 'Test notes',
      );

      final json = purchase.toJson();

      expect(json['notes'], 'Test notes');
    });

    test('should default notes to empty string if not provided in JSON', () {
      final json = {
        'id': '1',
        'supplierId': 's1',
      };

      final purchase = Purchase.fromJson(json);

      expect(purchase.notes, '');
    });
  });
}
