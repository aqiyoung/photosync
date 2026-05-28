import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/photo.dart';

class LocalDbService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'photosync.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE photos (
            id TEXT PRIMARY KEY,
            device_path TEXT NOT NULL,
            filename TEXT NOT NULL,
            file_size INTEGER,
            mime_type TEXT,
            width INTEGER,
            height INTEGER,
            created_at TEXT,
            modified_at TEXT,
            file_hash TEXT,
            sync_status TEXT DEFAULT 'pending',
            server_id INTEGER,
            synced_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            photo_id TEXT NOT NULL,
            status TEXT DEFAULT 'queued',
            retry_count INTEGER DEFAULT 0,
            error_message TEXT,
            created_at TEXT,
            FOREIGN KEY (photo_id) REFERENCES photos(id)
          )
        ''');
        await db.execute('CREATE INDEX idx_photos_sync ON photos(sync_status)');
        await db.execute('CREATE INDEX idx_photos_hash ON photos(file_hash)');
      },
    );
  }

  Future<void> insertPhoto(Photo photo) async {
    final db = await database;
    await db.insert('photos', photo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertPhotos(List<Photo> photos) async {
    final db = await database;
    final batch = db.batch();
    for (var photo in photos) {
      batch.insert('photos', photo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Photo>> getPhotos({int? limit, int? offset}) async {
    final db = await database;
    final maps = await db.query('photos', orderBy: 'created_at DESC', limit: limit, offset: offset);
    return maps.map((m) => Photo.fromMap(m)).toList();
  }

  Future<List<Photo>> getPendingPhotos() async {
    final db = await database;
    final maps = await db.query('photos', where: 'sync_status = ?', whereArgs: ['pending']);
    return maps.map((m) => Photo.fromMap(m)).toList();
  }

  Future<void> updateSyncStatus(String id, String status, {int? serverId}) async {
    final db = await database;
    final values = <String, Object?>{'sync_status': status};
    if (serverId != null) values['server_id'] = serverId;
    if (status == 'synced') values['synced_at'] = DateTime.now().toIso8601String();
    await db.update('photos', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateFileHash(String id, String hash) async {
    final db = await database;
    await db.update('photos', {'file_hash': hash}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getPhotoCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM photos');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getSyncedCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM photos WHERE sync_status = ?', ['synced']);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Photo?> getPhotoById(String id) async {
    final db = await database;
    final maps = await db.query('photos', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Photo.fromMap(maps.first);
  }
}
