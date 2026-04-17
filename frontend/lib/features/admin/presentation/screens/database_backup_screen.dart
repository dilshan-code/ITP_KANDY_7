// ------------------------------------------------------------------------------
// File: database_backup_screen.dart
// Purpose: Disaster recovery and data portability interface for Administrators.
// Rationale: Facilitates secure server-side ZIP archive generation of the 
//   entire business database. Implements persistent "Last Backup" tracking
//   via local preferences and integrates with the native share sheet for 
//   off-device storage.
// ------------------------------------------------------------------------------
import 'dart:io'; // IO: Filesystem handling for temporary storage
import 'package:flutter/material.dart'; // UI: Material toolkit
import 'package:shared_preferences/shared_preferences.dart'; // Storage: Local persistence for metadata
import 'package:intl/intl.dart'; // Formatting: Date/Time display
import 'package:animate_do/animate_do.dart'; // UI: Animations
import 'package:http/http.dart' as http; // Network: Raw HTTP streaming for zip downloads
import 'package:path_provider/path_provider.dart'; // Infrastructure: Platform path discovery
import 'package:share_plus/share_plus.dart'; // Infrastructure: Native sharing integration
import 'package:frontend/core/network/api_client.dart'; // Network: API base configuration
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger

class DatabaseBackupScreen extends StatefulWidget {
  const DatabaseBackupScreen({super.key});

  @override
  State<DatabaseBackupScreen> createState() => _DatabaseBackupScreenState();
}

class _DatabaseBackupScreenState extends State<DatabaseBackupScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _lastBackupTime = 'Never';
  final String _prefKey = 'last_database_backup_time';

  @override
  void initState() {
    super.initState();
    _loadLastBackupTime();
  }

  Future<void> _loadLastBackupTime() async {
    // Persistent retrieval: Accessing local storage to show the user's previous backup history.
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastBackupTime = prefs.getString(_prefKey) ?? 'Never';
    });
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'clickbuy_backup_$dateStr.zip';
      
      // 1. Start actual HTTP request to backend
      final client = http.Client();
      final request = http.Request('GET', Uri.parse('${ApiClient.baseUrl}/admin/backup'));
      
      // Inject headers from ApiClient
      final ownerId = ApiClient.ownerId;
      if (ownerId != null) {
        request.headers['x-owner-id'] = ownerId;
      }
      request.headers['Content-Type'] = 'application/json';

      final response = await client.send(request).timeout(const Duration(minutes: 5));

      if (response.statusCode != 200) {
        // Error handling: Catching server-side ZIP generation failures or unauthorized access.
        throw Exception('Server returned ${response.statusCode}');
      }

      // 2. Prepare local file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      final sink = file.openWrite();

      // 3. Stream bytes and update progress
      int downloaded = 0;
      final total = response.contentLength ?? 0;

      await response.stream.listen(
        (chunk) {
          // Streaming IO: Appending received bytes to a temporary local file to avoid RAM spikes.
          sink.add(chunk);
          downloaded += chunk.length;
          if (total > 0) {
            setState(() {
              _progress = downloaded / total;
            });
          } else {
            // Fallback animation if Content-Length is missing (streaming zip usually is)
            setState(() {
              _progress = (_progress + 0.05).clamp(0.0, 0.99);
            });
          }
        },
        onDone: () async {
          // Cleanup: Closing file handles and network client after full transfer.
          await sink.close();
          client.close();
          
          if (mounted) {
            setState(() => _progress = 1.0);
            await _handleDownloadComplete(file, fileName);
          }
        },
        onError: (e) {
          throw e;
        },
      ).asFuture();

    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDownloadComplete(File file, String fileName) async {
    final now = DateTime.now();
    final formattedTime = DateFormat('MMM d, y, h:mm a').format(now);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, formattedTime);
    
    setState(() {
      _isDownloading = false;
      _lastBackupTime = formattedTime;
    });

    // 4. Use share_plus to let user save the file
    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(file.path, name: fileName, mimeType: 'application/zip')],
      subject: 'ClickBuy Database Backup',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Backup ready to save!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Database Backup'),
        elevation: 0,
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeInDown(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.backup_rounded,
                          size: 40,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Secure Database Backup',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Download a compressed ZIP archive of the current Atlas database collections. Use this file for recovery if needed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Last Download:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                            Text(
                              _lastBackupTime,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (_isDownloading) ...[
                FadeInUp(
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _progress <= 0 ? null : _progress, // Shows indeterminate if 0
                        backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Generating ZIP archive... ${(_progress * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _startDownload,
                  icon: _isDownloading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _isDownloading ? 'Processing...' : 'Download Database (.zip)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.indigo.withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

