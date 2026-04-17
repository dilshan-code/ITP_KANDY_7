// ------------------------------------------------------------------------------
// File: backend_discovery.dart
// Purpose: Zero-Config Infrastructure Handshake and Network Discovery.
// Rationale: Implements a UDP-based broadcast listener that enables mobile 
//   devices to automatically detect the backend server IP on the local 
//   Wi-Fi. Eliminates the need for manual IP entry and facilitates 
//   plug-and-play field deployment.
// ------------------------------------------------------------------------------
import 'dart:async'; // Enables asynchronous control (Futures, Completers, Timers)
import 'dart:convert'; // Provides JSON and UTF-8 conversion tools
import 'dart:io'; // Library for lower-level networking (Sockets and HTTP)
import 'package:flutter/foundation.dart'; // Standard utilities and logging
import 'package:frontend/core/network/api_client.dart'; // Dependency: Updates API base configuration

class BackendDiscovery {
  // --- Network Configuration ---
  static const int _broadcastPort = 5555; // Port: Standardized discovery port for UDP traffic
  static RawDatagramSocket? _socket; // State: Active listener socket for UDP packets
  static bool _isSearching = false; // Guard: Prevents concurrent discovery threads
  static bool _hasDiscoveredBackend = false; // Flag: Signals successful discovery to the UI

  static bool get hasDiscoveredBackend => _hasDiscoveredBackend; // Query: Status for setup screens

  /*
   * Logic: Discovery Engine Orchestration.
   * Rationale: Opens an IPv4 UDP socket to listen for heartbeat broadcast 
   *   traffic. Implements thread-safety guards to prevent duplicate listeners.
   */
  static Future<void> startDiscovery() async {
    if (_isSearching) return; // Logic: Thread safety guard
    _isSearching = true;

    try {
      debugPrint('📡 [Discovery] Starting UDP discovery on port $_broadcastPort...');
      
      // Implementation: Bind to ANY IPv4 address on the specific discovery port.
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
      _socket?.broadcastEnabled = true; // Strategy: Permit the receipt of broadcast datagrams

      // Event Loop: Listen for incoming network events.
      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final Datagram? dg = _socket?.receive(); // Retrieval: Pull the raw network packet
          if (dg != null) {
            _processPacket(dg); // Logic: Hand off bytes for decoding and parsing
          }
        }
      });
    } catch (e) {
      debugPrint('❌ [Discovery] Failed to start UDP discovery: $e'); // Recovery: Log fatal socket error
      _isSearching = false; // Reset: Allow retry after failure
    }
  }

  /*
   * Logic: Resource Finalization.
   * Rationale: Closes the active network socket and clears internal state 
   *   to prevent memory leaks and port contention during app lifecycle transitions.
   */
  static void stopDiscovery() {
    _socket?.close(); // Cleanup: Terminate active connection
    _socket = null; // Reset: Clear reference
    _isSearching = false; // State: Mark search as inactive
    debugPrint('📡 [Discovery] Stopped.');
  }

  /*
   * Logic: Connectivity Handshake Waiter.
   * Rationale: Blocks high-level application flow (Splash) until a verified 
   *   backend is detected or timeout occurs. Prioritizes the restoration of 
   *   cached configurations for faster startup.
   */
  static Future<bool> waitForDiscovery({
    Duration timeout = const Duration(seconds: 8), // Strategy: Wait up to 8 seconds for a response
  }) async {
    // Stage 1: Fast Recovery. Check if a previously saved IP is still reachable.
    if (ApiClient.serverIp != '10.0.2.2') { // Condition: Skip if using default generic IP
      final reachable = await _isServerReachable(ApiClient.serverIp); // Logic: Direct ping
      if (reachable) {
        _hasDiscoveredBackend = true; // Success: Reuse existing config
        debugPrint('✅ [Discovery] Saved IP ${ApiClient.serverIp} is reachable.');
        return true;
      }
    }

    // Stage 2: Active Search. Start the UDP listener if not already running.
    if (!_isSearching) {
      await startDiscovery();
    }

    // Stage 3: Polling Cycle. Wait for the background listener to find a packet.
    final completer = Completer<bool>(); // Completion: Async boolean signal
    final deadline = DateTime.now().add(timeout); // Cutoff: Max wait time calculation

    // Implementation: Review discovery state every 500ms.
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_hasDiscoveredBackend || DateTime.now().isAfter(deadline)) {
        timer.cancel(); // Stop: End polling once result is known or expired
        if (!completer.isCompleted) {
          completer.complete(_hasDiscoveredBackend); // Signal: Notify the UI of final fate
        }
      }
    });

    return completer.future; // Future: Return the pending result
  }

  /*
   * Logic: Health Validation (L7 Ping).
   * Rationale: Performs a lightweight HTTP request to the /health route 
   *   of a discovered IP to confirm service responsiveness before activation.
   */
  static Future<bool> _isServerReachable(String ip) async {
    try {
      final uri = Uri.parse('http://$ip:5001/health'); // Endpoint: Dedicated liveness route
      final client = HttpClient(); // Implementation: Raw HTTP client for control
      client.connectionTimeout = const Duration(seconds: 3); // Strategy: Minimal timeout for speed
      final request = await client.getUrl(uri); // Action: Start GET request
      final response = await request.close().timeout(const Duration(seconds: 3)); // Action: Await reply
      client.close(); // Cleanup: Dispose client
      return response.statusCode == 200; // Success: 200 OK means the server is UP
    } catch (_) {
      return false; // Connection: Refused or timed out
    }
  }

  // Wrapper: Expose connection testing for manual setup dialogs.
  static Future<bool> testConnection(String ip) => _isServerReachable(ip);

  /**
   * Logic: Packet Decoder.
   * Parses the raw bytes from the wire into a ClickBuy discovery signature.
   */
  static void _processPacket(Datagram dg) {
    try {
      final String message = utf8.decode(dg.data); // Decode: Raw bytes to UTF8 string
      final Map<String, dynamic> data = jsonDecode(message); // Parse: String to JSON map

      // Security: Handshake signature verification.
      if (data['service'] == 'clickbuy' && data['ip'] != null) {
        final String foundIp = data['ip']; // Extract: Announced server IP
        
        // Strategy: Auto-update configuration if the server IP shifted.
        if (foundIp != ApiClient.serverIp) {
          debugPrint('✅ [Discovery] Found backend at: $foundIp');
          ApiClient.setServerIp(foundIp); // Logic: Propagate change to main API client
        }
        _hasDiscoveredBackend = true; // State: Global success signal
      }
    } catch (e) {
      // Failure: Silently drop malformed packets from unrelated network noise
    }
  }
}

