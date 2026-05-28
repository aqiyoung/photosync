import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/photo.dart';

class PhotoService {
  Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth;
  }

  Future<List<Photo>> scanDevicePhotos({int page = 0, int pageSize = 100}) async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return [];

    final assets = await albums[0].getAssetListPaged(page: page, size: pageSize);
    final photos = <Photo>[];

    for (var asset in assets) {
      final file = await asset.file;
      if (file == null) continue;

      photos.add(Photo(
        id: asset.id,
        devicePath: file.path,
        filename: asset.title ?? 'unknown',
        fileSize: await file.length(),
        mimeType: asset.mimeType ?? 'image/jpeg',
        width: asset.width,
        height: asset.height,
        createdAt: asset.createDateTime.toIso8601String(),
        modifiedAt: asset.modifiedDateTime.toIso8601String(),
      ));
    }

    return photos;
  }

  Future<String> calculateFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Uint8List> getThumbnail(String assetId, {int width = 200, int height = 200}) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return Uint8List(0);
    final thumb = await asset.thumbnailDataWithSize(ThumbnailSize(width, height));
    return thumb ?? Uint8List(0);
  }

  Future<File?> getOriginalFile(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    return await asset?.file;
  }
}
