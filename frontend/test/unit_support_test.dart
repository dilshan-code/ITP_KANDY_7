import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/products/domain/entities/product.dart';

void main() {
  group('Product Unit Support Tests', () {
    test('Product should correctly store and retrieve unit', () {
      final product = Product(
        id: '1',
        name: 'Rice',
        description: 'Basmati Rice',
        category: 'Grains & Staples',
        sellingPrice: 120.0,
        stockQuantity: 50,
        minimumStockLevel: 5,
        unit: 'kg',
      );

      expect(product.unit, 'kg');
    });

    test('Product JSON serialization should include unit', () {
      final json = {
        'id': '2',
        'name': 'Bread',
        'description': 'White Bread',
        'category': 'Bakery',
        'sellingPrice': 60.0,
        'stockQuantity': 10,
        'minimumStockLevel': 2,
        'unit': 'items',
      };

      final product = Product.fromJson(json);
      expect(product.unit, 'items');

      final backToJson = product.toJson();
      expect(backToJson['unit'], 'items');
    });

    test('Product default unit should be ea if not specified', () {
      final json = {
        'id': '3',
        'name': 'Apple',
        'description': 'Red Apple',
        'category': 'Fruits',
        'sellingPrice': 30.0,
        'stockQuantity': 100,
        'minimumStockLevel': 10,
        // unit not specified
      };

      final product = Product.fromJson(json);
      expect(product.unit, 'ea');
    });
  });
}
