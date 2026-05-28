import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/photo.dart';
import 'auth_service.dart';
import 'local_db_service.dart';
import 'photo_service.dart';

class SyncService {
  final AuthService _authService;
  final LocalDbService _dbService;
  final PhotoService _photoService;
  final Dio _dio = Dio();
  bool _isSyncing = false;

  SyncService(this._authService, this._dbService, this._photoService);

  bool get isSyncing => _isSyncing;

  Future<void> startSync() async {
    if (_isSyncing || !_authService.isLoggedIn) return;
    _isSyncing = true;

    try {
      // 1. Scan device photos
      await _scanAndIndexPhotos();

      // 2. Get pending photos
      final pendingPhotos = await _dbService.getPendingPhotos();

      // 3. Check which are already synced on server
      final hashes = pendingPhotos
          .where((p) => p.fileHash != null)
          .map((p) => p.fileHash!)
          .toList();

      if (hashes.isNotEmpty) {
        final syncedHashes = await _checkSyncStatus(hashes);
        for (var photo in pendingPhotos) {
          if (photo.fileHash != null && syncedHashes.contains(photo.fileHash)) {
            await _dbService.updateSyncStatus(photo.id, 'synced');
          }
        }
      }

      // 4. Upload remaining pending photos
      final stillPending = await _dbService.getPendingPhotos();
      for (var photo in stillPending) {
        await _uploadPhoto(photo);
      }
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _scanAndIndexPhotos() async {
    int page = 0;
    bool hasMore = true;

    while (hasMore) {
      final photos = await _photoService.scanDevicePhotos(page: page, pageSize: 100);
      if (photos.isEmpty) {
        hasMore = false;
        break;
      }

      for (var photo in photos) {
        final existing = await _dbService.getPhotoById(photo.id);
        if (existing == null) {
          final hash = await _photoService.calculateFileHash(photo.devicePath);
          await _dbService.insertPhoto(photo.copyWith(fileHash: hash));
        }
      }

      page++;
    }
  }

  Future<Set<String>> _checkSyncStatus(List<String> hashes) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.apiBaseUrl}/photos/check-sync',
        data: {'hashes': hashes},
        options: Options(headers: _authService.authHeaders),
      );

      if (response.data['code'] == 0) {
        return Set<String>.from(response.data['data']['synced_hashes']);
      }
    } catch (e) {
      print('Check sync error: $e');
    }
    return {};
  }

  Future<void> _uploadPhoto(Photo photo) async {
    try {
      await _dbService.updateSyncStatus(photo.id, 'uploading');

      final file = File(photo.devicePath);
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photo.devicePath, filename: photo.filename),
        'created_at': photo.createdAt,
        'width': photo.width.toString(),
        'height': photo.height.toString(),
      });

      final response = await _dio.post(
        '${ApiConfig.apiBaseUrl}/photos/upload',
        data: formData,
        options: Options(headers: _authService.authHeaders),
      );

      if (response.data['code'] == 0) {
        final serverId = response.data['data']['id'];
        await _dbService.updateSyncStatus(photo.id, 'synced', serverId: serverId);
      } else {
        await _dbService.updateSyncStatus(photo.id, 'failed');
      }
    } catch (e) {
      await _dbService.updateSyncStatus(photo.id, 'failed');
      print('Upload error: $e');
    }
  }

  Future<Map<String, int>> getSyncStats() async {
    final total = await _dbService.getPhotoCount();
    final synced = await _dbService.getSyncedCount();
    return {
      'total': total,
      'synced': synced,
      'pending': total - synced,
    };
  }
}
