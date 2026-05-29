import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../services/gemini_service.dart';
import '../models/plant_catalog_model.dart';

/// ──────────────────────────────────────────────
/// SyncService — Monitors network connectivity and
/// manages synchronization of local SQLite records
/// to Firebase Cloud Firestore.
/// ──────────────────────────────────────────────
class SyncService extends ChangeNotifier {
  bool _isOnline = false;
  bool _isSyncing = false;
  int _pendingCount = 0;
  String? _userId;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;

  void updateUser(String? userId) {
    _userId = userId;
  }

  /// Start listening for connectivity changes.
  void startMonitoring() {
    Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);

      if (_isOnline && !wasOnline) {
        debugPrint('[SyncService] Network restored — triggering sync.');
        _triggerSync();
      }

      notifyListeners();
    });

    // Check initial status
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    notifyListeners();
  }

  /// Manually trigger synchronization.
  Future<void> syncNow() async {
    if (!_isOnline) return;
    await _triggerSync();
  }

  Future<String?> _uploadToImgBB(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('imgbb_api_key');
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': apiKey,
          'image': base64Image,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url']; 
      } else {
        debugPrint('ImgBB Upload failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('ImgBB Upload Error: $e');
      return null;
    }
  }

  /// Internal sync logic.
  Future<void> _triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Process Offline Queue via Gemini
      final pendingRecords = await DatabaseHelper.instance.getPendingVerifications();
      
      if (pendingRecords.isNotEmpty) {
        final geminiService = GeminiService();
        final hasKey = await geminiService.hasApiKey();
        
        if (hasKey) {
          for (final record in pendingRecords) {
            try {
              final imageFile = File(record.imagePath);
              if (await imageFile.exists()) {
                final result = await geminiService.identifyPlant(imageFile).timeout(const Duration(seconds: 15));
                if (result != null) {
                  final updatedRecord = record.copyWith(
                    scientificName: result['scientificName'] ?? 'Unknown',
                    commonName: result['commonName'] ?? 'Unknown',
                    confidenceScore: (result['confidence'] ?? 0.0).toDouble(),
                    xaiReasoning: result['xaiReasoning'] ?? 'Verified.',
                    safetyWarnings: result['safetyWarnings'],
                    preparationMethods: result['preparationNotes'],
                    family: result['family'],
                    edibilityStatus: result['edibilityStatus'],
                    habitat: result['habitat'],
                    nutritionalHighlights: result['nutritionalHighlights'],
                    verificationStatus: 'verified',
                  );
                  await DatabaseHelper.instance.updatePlantRecord(updatedRecord);
                  debugPrint('[SyncService] Verified record ${record.id}');
                }
              }
            } catch (e) {
              debugPrint('[SyncService] Failed to verify record ${record.id}: $e');
            }
          }
        }
      }

      // 2. Firebase Sync Push (Backup)
      if (_userId != null) {
        final unsyncedRecords = await DatabaseHelper.instance.getUnsyncedRecords(_userId!);
        final firestore = FirebaseFirestore.instance;
        final userDoc = firestore.collection('users').doc(_userId);

        for (final record in unsyncedRecords) {
          try {
            String imageUrl = record.imagePath;
            
            // Upload to ImgBB if it's a local file and not already a URL
            if (!imageUrl.startsWith('http')) {
              final imageFile = File(imageUrl);
              if (await imageFile.exists()) {
                final uploadedUrl = await _uploadToImgBB(imageFile);
                if (uploadedUrl != null) {
                  imageUrl = uploadedUrl;
                }
              }
            }

            final data = record.toMap();
            data['image_path'] = imageUrl; // Replace local path with remote URL in cloud
            data['is_synced'] = 1;

            await userDoc.collection('herbarium').doc(record.id.toString()).set(data).timeout(const Duration(seconds: 10));

            // Update local record to mark as synced
            final syncedRecord = record.copyWith(isSynced: 1);
            await DatabaseHelper.instance.updatePlantRecord(syncedRecord);
            debugPrint('[SyncService] Synced record ${record.id} to Cloud');
          } catch (e) {
            debugPrint('[SyncService] Failed to sync record to Cloud ${record.id}: $e');
          }
        }

        final remaining = await DatabaseHelper.instance.getUnsyncedRecords(_userId!);
        _pendingCount = remaining.length;
      }
      
      debugPrint('[SyncService] Sync complete.');
    } catch (e) {
      debugPrint('[SyncService] Sync failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Pull records from Cloud to local device
  Future<void> pullFromCloud() async {
    if (_userId == null || !_isOnline) return;
    
    _isSyncing = true;
    notifyListeners();

    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('users')
          .doc(_userId)
          .collection('herbarium')
          .get()
          .timeout(const Duration(seconds: 15));

      final localRecords = await DatabaseHelper.instance.getUserPlantRecords(_userId!);
      final localIds = localRecords.map((e) => e.id.toString()).toSet();

      for (var doc in snapshot.docs) {
        final cloudId = doc.id;
        if (!localIds.contains(cloudId)) {
          // It's a new record from the cloud!
          final data = doc.data();
          data['id'] = int.tryParse(cloudId);
          data['is_synced'] = 1;
          
          final newRecord = PlantCatalogModel.fromMap(data);
          await DatabaseHelper.instance.insertPlantRecord(newRecord);
          debugPrint('[SyncService] Pulled record $cloudId from Cloud');
        }
      }
    } catch (e) {
      debugPrint('[SyncService] Pull from cloud failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Update the pending count for display in the UI.
  void updatePendingCount(int count) {
    _pendingCount = count;
    notifyListeners();
  }
}
