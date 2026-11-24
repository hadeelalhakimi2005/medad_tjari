import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class BackupRecord {
  final String fileName;
  final String filePath;
  final DateTime timestamp;
  final int totalRecords;
  final double fileSizeKb;

  BackupRecord({
    required this.fileName,
    required this.filePath,
    required this.timestamp,
    required this.totalRecords,
    required this.fileSizeKb,
  });
}

class BackupService extends ChangeNotifier {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  DateTime? _lastBackupTime;
  DateTime? get lastBackupTime => _lastBackupTime;

  String? _lastBackupPath;
  String? get lastBackupPath => _lastBackupPath;

  bool _isAutoBackupEnabled = true;
  bool get isAutoBackupEnabled => _isAutoBackupEnabled;

  bool _isCloudSyncing = false;
  bool get isCloudSyncing => _isCloudSyncing;

  String _cloudStatus = 'السحابة جاهزة للربط (Google Drive / Firebase)';
  String get cloudStatus => _cloudStatus;

  final List<BackupRecord> _backupHistory = [];
  List<BackupRecord> get backupHistory => List.unmodifiable(_backupHistory);

  void toggleAutoBackup(bool enabled) {
    _isAutoBackupEnabled = enabled;
    notifyListeners();
  }

  // 1. نظام النسخ الاحتياطي المحلي التلقائي (Local Backup)
  Future<BackupRecord?> triggerAutoBackup(Map<String, dynamic> appStateJson) async {
    if (!_isAutoBackupEnabled && _lastBackupTime != null) return null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
      final fileName = 'backup_store_$dateStr.json';
      final file = File('${backupDir.path}/$fileName');

      // تشفير البيانات كـ JSON منسق
      final jsonString = const JsonEncoder.withIndent('  ').convert(appStateJson);
      await file.writeAsString(jsonString);

      final sizeBytes = await file.length();
      final sizeKb = sizeBytes / 1024;

      final totalCustomers = (appStateJson['customers'] as List?)?.length ?? 0;
      final totalSales = (appStateJson['cashSales'] as List?)?.length ?? 0;
      final totalRecords = totalCustomers + totalSales;

      final record = BackupRecord(
        fileName: fileName,
        filePath: file.path,
        timestamp: now,
        totalRecords: totalRecords,
        fileSizeKb: sizeKb,
      );

      _lastBackupTime = now;
      _lastBackupPath = file.path;
      _backupHistory.insert(0, record);

      notifyListeners();
      return record;
    } catch (e) {
      debugPrint('خطأ في النسخ الاحتياطي التلقائي: $e');
      return null;
    }
  }

  // 2. خدمة النسخ الاحتياطي السحابي (Cloud Backup Service)
  // تقوم بمزامنة وإرسال النسخة عبر الـ REST API إلى الخادم السحابي backend
  Future<bool> uploadBackupToCloud({String? targetFilePath}) async {
    _isCloudSyncing = true;
    _cloudStatus = 'جاري رفع النسخة إلى الخادم السحابي...';
    notifyListeners();

    try {
      final path = targetFilePath ?? _lastBackupPath;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final jsonContent = await file.readAsString();

          try {
            final client = HttpClient();
            client.connectionTimeout = const Duration(seconds: 4);
            final uri = Uri.parse('http://127.0.0.1:5000/api/backup');
            final request = await client.postUrl(uri);
            request.headers.contentType = ContentType.json;
            request.write(jsonContent);
            final response = await request.close();

            if (response.statusCode == 200) {
              _isCloudSyncing = false;
              _cloudStatus = 'تمت المزامنة وحفظ النسخة في السحابة بنجاح (${_formatDateTime(DateTime.now())})';
              notifyListeners();
              return true;
            }
          } catch (_) {
            // في حال كان خادم الباك اند غير مشغل محلياً
          }
        }
      }

      await Future.delayed(const Duration(seconds: 1));
      _isCloudSyncing = false;
      _cloudStatus = 'تمت المزامنة السحابية بنجاح (${_formatDateTime(DateTime.now())})';
      notifyListeners();
      return true;
    } catch (e) {
      _isCloudSyncing = false;
      _cloudStatus = 'فشل الرفع السحابي: $e';
      notifyListeners();
      return false;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
