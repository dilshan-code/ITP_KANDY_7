import 'dart:convert';
import 'package:http/http.dart' as http;

/// Central service class for all backend API calls.
/// ඔයාගේ backend localhost:3000 ට connect කරනවා.
/// Real device test කරනවනම් localhost වෙනුවට ඔයාගේ computer IP දාන්න.
class ApiService {
  // Android emulator: 10.0.2.2  |  Real device: ඔයාගේ WiFi IP (e.g. 192.168.1.5)
  static const String _baseUrl = 'http://localhost:3000/api';

  // ─── Products ──────────────────────────────────────────────────────────────

  /// Firebase 'products' collection ගෙන් ඔක්කොම products ගන්නවා
  static Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await http.get(Uri.parse('$_baseUrl/products'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load products: ${response.body}');
  }

  // ─── Sales ─────────────────────────────────────────────────────────────────

  /// නව sale create කරනවා — stock deduction + credit customer update ත් backend කරනවා
  static Future<Map<String, dynamic>> createSale({
    required String customerName,
    required bool isCredit,
    required String status,
    required double subtotal,
    required double tax,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sales'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customerName': customerName,
        'isCredit': isCredit,
        'status': status,
        'subtotal': subtotal,
        'tax': tax,
        'totalAmount': totalAmount,
        'date': DateTime.now().toIso8601String(),
        'items': items,
      }),
    );
    if (response.statusCode == 201) {
      final body = json.decode(response.body);
      return body['data'];
    }
    throw Exception('Failed to create sale: ${response.body}');
  }

  /// ඔක්කොම sales history ගන්නවා
  static Future<List<Map<String, dynamic>>> getSales() async {
    final response = await http.get(Uri.parse('$_baseUrl/sales'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load sales: ${response.body}');
  }

  /// Single sale + items
  static Future<Map<String, dynamic>> getSaleById(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/sales/$id'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['data'];
    }
    throw Exception('Sale not found');
  }

  /// Date range report — from/to ISO strings
  static Future<Map<String, dynamic>> getSalesReport(
    String from,
    String to,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/sales/report?from=$from&to=$to'),
    );
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['data'];
    }
    throw Exception('Failed to load report: ${response.body}');
  }

  /// Dashboard stats
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(Uri.parse('$_baseUrl/dashboard'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['data'];
    }
    throw Exception('Failed to load dashboard: ${response.body}');
  }
}
