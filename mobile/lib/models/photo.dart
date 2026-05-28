class Photo {
  final String id;
  final String devicePath;
  final String filename;
  final int fileSize;
  final String mimeType;
  final int width;
  final int height;
  final String createdAt;
  final String? modifiedAt;
  final String? fileHash;
  final String syncStatus; // pending, uploading, synced, failed
  final int? serverId;
  final String? syncedAt;

  Photo({
    required this.id,
    required this.devicePath,
    required this.filename,
    required this.fileSize,
    required this.mimeType,
    required this.width,
    required this.height,
    required this.createdAt,
    this.modifiedAt,
    this.fileHash,
    this.syncStatus = 'pending',
    this.serverId,
    this.syncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_path': devicePath,
      'filename': filename,
      'file_size': fileSize,
      'mime_type': mimeType,
      'width': width,
      'height': height,
      'created_at': createdAt,
      'modified_at': modifiedAt,
      'file_hash': fileHash,
      'sync_status': syncStatus,
      'server_id': serverId,
      'synced_at': syncedAt,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'],
      devicePath: map['device_path'],
      filename: map['filename'],
      fileSize: map['file_size'] ?? 0,
      mimeType: map['mime_type'] ?? '',
      width: map['width'] ?? 0,
      height: map['height'] ?? 0,
      createdAt: map['created_at'] ?? '',
      modifiedAt: map['modified_at'],
      fileHash: map['file_hash'],
      syncStatus: map['sync_status'] ?? 'pending',
      serverId: map['server_id'],
      syncedAt: map['synced_at'],
    );
  }

  Photo copyWith({
    String? syncStatus,
    int? serverId,
    String? syncedAt,
    String? fileHash,
  }) {
    return Photo(
      id: id,
      devicePath: devicePath,
      filename: filename,
      fileSize: fileSize,
      mimeType: mimeType,
      width: width,
      height: height,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      fileHash: fileHash ?? this.fileHash,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
}
