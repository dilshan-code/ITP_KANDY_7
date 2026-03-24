import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ApiClient handles all network requests (HTTP) to our Node.js backend.
class ApiClient {
  // Determine the correct backend URL based on the platform running the app.
  // Use 10.0.2.2 for Android emulator, localhost for web/desktop
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    // For Android emulator, 10.0.2.2 maps to host's localhost
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }

    // Fallback for Windows/desktop testing
    return 'http://localhost:3000/api';
  }

  // Perform an HTTP GET request to fetch data from the backend
  static Future<Map<String, dynamic>> get(String path) async {
    // Send a GET request to the concatenated URL
    final response = await http.get(Uri.parse('$baseUrl$path'));
    // 200 OK means the request was completely successful
    if (response.statusCode == 200) {
      // Decode the JSON response string into a Dart Map so Flutter can read the fields
      return jsonDecode(response.body);
    }
    // Try to extract the specific error message
    String? errorMessage;
    try {
      final errorData = jsonDecode(response.body);
      if (errorData['error'] != null) {
        errorMessage = errorData['error'];
      }
    } catch (_) {}

    if (errorMessage != null) {
      throw Exception(errorMessage);
    }
    // If not 200, throw a dart Exception that can be caught by the UI
    throw Exception('Failed to load data: ${response.statusCode}');
  }

  // Perform an HTTP POST request to send new data to the backend
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      // Tell the NodeJS backend we are sending JSON data
      headers: {'Content-Type': 'application/json'},
      // Encode the Dart Map into a JSON string before sending it over the network
      body: jsonEncode(body),
    );
    // 200 OK or 201 Created indicate success
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    // Try to extract the specific error message provided by the backend
    String? errorMessage;
    try {
      final errorData = jsonDecode(response.body);
      if (errorData['error'] != null) {
        errorMessage = errorData['error'];
      }
    } catch (_) {
      // If decoding fails, fallback to standard error message
    }

    if (errorMessage != null) {
      throw Exception(errorMessage);
    }
    throw Exception('Failed to create: ${response.statusCode}');
  }

  // Perform an HTTP PUT request to update existing data
  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    String? errorMessage;
    try {
      final errorData = jsonDecode(response.body);
      if (errorData['error'] != null) {
        errorMessage = errorData['error'];
      }
    } catch (_) {}

    if (errorMessage != null) {
      throw Exception(errorMessage);
    }
    throw Exception('Failed to update: ${response.statusCode}');
  }

  // Perform an HTTP DELETE request to remove data
  static Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(Uri.parse('$baseUrl$path'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    String? errorMessage;
    try {
      final errorData = jsonDecode(response.body);
      if (errorData['error'] != null) {
        errorMessage = errorData['error'];
      }
    } catch (_) {}

    if (errorMessage != null) {
      throw Exception(errorMessage);
    }
    throw Exception('Failed to delete: ${response.statusCode}');
  }
}
