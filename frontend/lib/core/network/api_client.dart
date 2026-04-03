import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ApiClient handles all network requests (HTTP) to our Node.js backend.
class ApiClient {
  // Determine the correct backend URL based on the platform running the app.
  // Use 10.0.2.2 for Android emulator, localhost for web/desktop
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5001/api';
    }

    // For Android emulator, 10.0.2.2 maps to host's localhost
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5001/api';
    }

    // Fallback for Windows/desktop testing
    return 'http://localhost:5001/api';
  }

  // Store the ownerId globally in the app after login
  static String? ownerId;

  // Helper to build headers with ownerId
  static Map<String, String> get _headers {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-timezone-offset': DateTime.now().timeZoneOffset.inMinutes.toString(),
    };
    if (ownerId != null) {
      headers['x-owner-id'] = ownerId!;
    }
    return headers;
  }

  // Perform an HTTP GET request to fetch data from the backend
  static Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParameters}) async {
    Uri uri = Uri.parse('$baseUrl$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }

    final response = await http.get(
      uri,
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_handleError(response));
  }

  // Perform an HTTP POST request to send new data to the backend
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception(_handleError(response));
  }

  // Perform an HTTP PUT request to update existing data
  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_handleError(response));
  }

  // Perform an HTTP PATCH request to update part of the existing data
  static Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_handleError(response));
  }

  // Perform an HTTP DELETE request to remove data
  static Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_handleError(response));
  }

  // Centralized error handling and quota detection
  static String _handleError(http.Response response) {
    String? errorMessage;
    try {
      final errorData = jsonDecode(response.body);
      if (errorData['error'] != null) {
        errorMessage = errorData['error'];
      }
    } catch (_) {}

    final finalMessage = errorMessage ?? 'Request failed (${response.statusCode})';

    // Detect Firestore Quota Exhaustion (Code 8 / RESOURCE_EXHAUSTED)
    if (finalMessage.toUpperCase().contains('RESOURCE_EXHAUSTED') ||
        finalMessage.contains('QUOTA EXCEEDED')) {
      return 'Cloud Database Quota Exhausted. Operation failed. Please try again tomorrow.';
    }

    return finalMessage;
  }
}
