// ------------------------------------------------------------------------------
// File: api_client.dart
// Purpose: Deterministic Network Gateway for Multi-Tenant Data.
// Rationale: Orchestrates all HTTP communication between the Flutter app and 
//   the Node.js backend. Implements dynamic infrastructure discovery, 
//   identity injection (header-based isolation), and unified HTTP error 
//   mapping to ensure cluster reliability.
// ------------------------------------------------------------------------------
import 'dart:convert'; // Library for JSON encoding/decoding and UTF-8 handling
import 'dart:io'; // Library for core networking (SocketException, HttpClient)
import 'dart:async'; // Library for asynchronous control (Futures, Timers, Timeouts)
import 'package:http/http.dart' as http; // Primary external HTTP client for Dart
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, kReleaseMode; // Utility flags, console logging, and mode detection
import 'package:shared_preferences/shared_preferences.dart'; // Local persistence for server configuration
import 'package:frontend/core/error/exceptions.dart'; // Custom domain exceptions for ClickBuy

class ApiClient {
  // --- Infrastructure Settings ---
  // Default: Replit production hostname for real devices.
  // Developers can override to a local IP via the Server Connection dialog (10s logo hold).
  static String _serverIp = 'ba408787-5deb-46ee-bb7e-679a94333377-00-3jxj82plhfdn2.sisko.replit.dev';
  static int _serverPort = 3000; // State: Active server port (Default: 3000)
  static const String _storageKeyIp = 'backend_server_ip'; // Registry: Key for local persistence
  static const String _storageKeyPort = 'backend_server_port'; // Registry: Key for port persistence
  static const String _storageKeyToken = 'backend_auth_token'; // Security: Key for JWT persistence
  
  // --- Multi-Tenant Context ---
  static String? _token; // Security: Active JWT session token
  static String? ownerId; // Scope: Current logged-in shop owner ID for data isolation
  static String? ownerName; // Audit: Owner name for server-side logging and history

  /*
   * Logic: Infrastructure Configuration.
   * Rationale: Loads the active server registry from local persistence to 
   *   resume connectivity after application restarts.
   */
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance(); // Access: Local disk storage
      final savedIp = prefs.getString(_storageKeyIp); // Retrieval: Get the last known IP
      if (savedIp != null && savedIp.isNotEmpty) {
        _serverIp = savedIp; // Update: Apply saved configuration to current session
        debugPrint('📡 [ApiClient] Loaded saved IP: $_serverIp');
      }
      
      final savedPort = prefs.getInt(_storageKeyPort); // Retrieval: Get the last known Port
      if (savedPort != null) {
        _serverPort = savedPort;
        debugPrint('📡 [ApiClient] Loaded saved Port: $_serverPort');
      }

      _token = prefs.getString(_storageKeyToken); // Retrieval: Load active security token
      if (_token != null) {
        debugPrint('🛡️ [ApiClient] Session token loaded from storage.');
      }
    } catch (e) {
      debugPrint('❌ [ApiClient] Failed to load saved settings: $e'); // Log: Fault in storage access
    }
  }

  /*
   * Logic: Manual Configuration Override.
   * Rationale: Updates the active server IP and persists it for future 
   *   sessions. Primarily utilized by the Backend Discovery engine.
   */
  static Future<void> setServerIp(String ip) async {
    if (ip == _serverIp) return; // Optimization: Skip if the value hasn't changed
    
    _serverIp = ip; // State: Update active memory
    try {
      final prefs = await SharedPreferences.getInstance(); // Access: Local disk storage
      await prefs.setString(_storageKeyIp, ip); // Commit: Persist new IP to disk
      debugPrint('✅ [ApiClient] Server IP updated to: $ip');
    } catch (e) {
      debugPrint('❌ [ApiClient] Failed to save IP: $e'); // Log: Persistence failure
    }
  }

  /*
   * Logic: Port Selection Override.
   */
  static Future<void> setServerPort(int port) async {
    if (port == _serverPort) return;
    
    _serverPort = port;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_storageKeyPort, port);
      debugPrint('✅ [ApiClient] Server Port updated to: $port');
    } catch (e) {
      debugPrint('❌ [ApiClient] Failed to save Port: $e');
    }
  }

  /*
   * Logic: Security Context Management.
   * Rationale: Updates the active JWT session token and persists it to disk. 
   *   Used during login to seal the session and during logout to wipe it.
   */
  static Future<void> setToken(String? token) async {
    _token = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token == null) {
        await prefs.remove(_storageKeyToken); // Wipe: Clear token on logout
      } else {
        await prefs.setString(_storageKeyToken, token); // Commit: Secure token persistence
      }
    } catch (e) {
      debugPrint('❌ [ApiClient] Failed to save token: $e');
    }
  }

  /*
   * Logic: Dynamic Endpoint Resolution.
   * Rationale: Constructs the API root by detecting the current execution 
   *   platform and utilizing the discovered network registry.
   */
  static String get baseUrl {
    // Strategy: Use the live Replit production server for the final APK (Release mode).
    // This removes the dependency on local Wi-Fi for actual users.
    if (kReleaseMode) {
      return 'https://ba408787-5deb-46ee-bb7e-679a94333377-00-3jxj82plhfdn2.sisko.replit.dev/api';
    }

    // Strategy: Detect if the configured server address is a hostname (e.g. Replit domain)
    // rather than a bare IP address. Hostnames use HTTPS and don't need a port suffix.
    if (_isHostname(_serverIp)) {
      return 'https://$_serverIp/api';
    }

    if (kIsWeb) {
      return 'http://localhost:$_serverPort/api'; // Dev: Use dynamic port
    } else {
      return 'http://$_serverIp:$_serverPort/api'; // Development/Mobile: Use dynamic port
    }
  }

  /// Detects if the given address is a hostname (e.g. `xyz.replit.dev`) vs a bare IP (e.g. `192.168.1.5`).
  static bool _isHostname(String address) {
    // A bare IPv4 address is all digits and dots. Anything else is a hostname.
    return address.contains('.') && !RegExp(r'^[\d.]+$').hasMatch(address);
  }

  static String get serverIp => _serverIp; // Query: Current active IP for UI displays
  static int get serverPort => _serverPort; // Query: Current active Port

  /*
   * Logic: Contextual Header Injection.
   * Rationale: Compiles secure multi-tenant identities and localization 
   *   metadata for every outgoing infrastructure request.
   */
  static Map<String, String> get headers {
    final Map<String, String> headersMap = {
      'Content-Type': 'application/json', // Protocol: All communication is JSON
      'x-timezone-offset': DateTime.now().timeZoneOffset.inMinutes.toString(), // Logic: Device timezone for reports
    };
    if (ownerId != null) {
      headersMap['x-owner-id'] = ownerId!; // Security: Isolate data queries to this owner
    }
    if (ownerName != null) {
      headersMap['x-owner-name'] = ownerName!; // Audit: Track which owner performed the action
    }
    if (_token != null) {
      headersMap['Authorization'] = 'Bearer $_token'; // Security: Sealed and signed session identity
    }
    return headersMap;
  }

  // --- HTTP Methods: REST Implementation ---

  // Standard GET: Fetch collection or record
  static Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParameters}) async {
    try {
      Uri uri = Uri.parse('$baseUrl$path'); // Resolution: Full endpoint URL
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters); // Filter: Append URL queries (e.g. ?id=1)
      }

      final response = await http.get(
        uri, // Target: Fully qualified URL
        headers: headers, // Context: Multi-tenant headers
      ).timeout(const Duration(seconds: 15)); // Constraint: Prevent infinite hangs

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Success: Map data to dynamic JSON
      }
      throw handleError(response); // Failure: Status-based error mapping
    } catch (e) {
      throw _handleException(e); // Recovery: Unified network failure handling
    }
  }

  // Standard POST: Create new record
  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'), // Target
        headers: headers, // Headers
        body: jsonEncode(body), // Payload: Serialize map to JSON string
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body); // Success
      }
      throw handleError(response); // Failure
    } catch (e) {
      throw _handleException(e); // Exception
    }
  }

  // Standard PUT: Full update
  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw handleError(response);
    } catch (e) {
      throw _handleException(e);
    }
  }

  // Standard PATCH: Partial update
  static Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw handleError(response);
    } catch (e) {
      throw _handleException(e);
    }
  }

  // Standard DELETE: Resource removal
  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw handleError(response);
    } catch (e) {
      throw _handleException(e);
    }
  }

  /*
   * Logic: HTTP Semantic Status Decoder.
   * Rationale: Translates raw network results into high-fidelity domain 
   *   exceptions with embedded technical diagnostics for troubleshooting.
   */
  static AppException handleError(http.Response response) {
    String? serverMessage; // Hint: Actual reason from the backend
    try {
      final errorData = jsonDecode(response.body); // Parse: Extract backend error payload
      serverMessage = errorData['error'] ?? errorData['message']; // Field mapping
    } catch (_) {}

    final statusCode = response.statusCode; // Code: 400, 401, 404, etc.
    final technicalDetails = 'Error Code: $statusCode${serverMessage != null ? '\nResponse: $serverMessage' : ''}'; // Diagnostic string

    // Special: Handle infrastructure/quota issues
    if (serverMessage != null) {
      final upperMsg = serverMessage.toUpperCase();
      if (upperMsg.contains('RESOURCE_EXHAUSTED') || upperMsg.contains('QUOTA EXCEEDED')) {
        return QuotaExceededException(serverMessage, technicalDetails);
      }
    }

    // Mapping: Standard HTTP Error Codes
    switch (statusCode) {
      case 400: // Bad Request
        return ValidationException(serverMessage, technicalDetails);
      case 401: // Unauthorized
        return AuthException(serverMessage, technicalDetails);
      case 403: // Forbidden
        return ForbiddenException(serverMessage, technicalDetails);
      case 404: // Not Found
        return NotFoundException(serverMessage, technicalDetails);
      case 500: // Internal Server Error
      case 502: // Bad Gateway
      case 503: // Service Unavailable
        return ServerException(serverMessage, technicalDetails);
      default: // Fallback
        return AppException(
          serverMessage ?? 'Request failed with status: $statusCode',
          'HTTP_$statusCode',
          technicalDetails,
        );
    }
  }

  /*
   * Logic: Low-Level Fault Recovery.
   * Rationale: Serves as a catch-all mapper for non-HTTP exceptions, 
   *   such as host unreachability or connection timeouts.
   */
  static Exception _handleException(Object e) {
    if (e is AppException) return e; // Pass-through: Already mapped exceptions
    
    final exceptionInfo = 'Exception: ${e.runtimeType}\nDetails: ${e.toString()}'; // Trace: Detailed debug info
    
    // Scenario: Device has no Wi-fi/Data or Airplane Mode is ON
    if (e is SocketException) {
      const code = 503; // Logic: Service Unavailable
      final technicalInfo = 'Error Code: $code\n$exceptionInfo';
      return NetworkException(null, technicalInfo);
    }
    
    // Scenario: Server exists but is under too much load or ISP lag is high
    if (e is TimeoutException) {
      const code = 408; // Logic: Request Timeout
      final technicalInfo = 'Error Code: $code\n$exceptionInfo';
      return NetworkException(
        'Request timed out. Please check your connection and try again.',
        technicalInfo,
      );
    }

    // Scenario: Connection refused (Server is actually OFF)
    final errorStr = e.toString();
    if (errorStr.contains('ClientException') || 
        errorStr.contains('Failed to fetch') || 
        errorStr.contains('Connection refused')) {
      const code = 503; // Logic: Service Unavailable
      final technicalInfo = 'Error Code: $code\n$exceptionInfo';
      return NetworkException(
        'Unable to connect to the server. Please ensure the backend is running and try again.',
        technicalInfo,
      );
    }

    // Scenario: Unexpected application crash during network call
    const code = 500; // Logic: Internal Fallback
    final technicalInfo = 'Error Code: $code\n$exceptionInfo';
    return AppException('Something went wrong. Please try again later.', code.toString(), technicalInfo);
  }
}

