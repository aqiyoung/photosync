import 'package:flutter/material.dart';
import '../models/photo.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';

class GalleryScreen extends StatefulWidget {
  final LocalDbService dbService;
  final SyncService syncService;

  const GalleryScreen({
    super.key,
    required this.dbService,
    required this.syncService,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Photo> _photos = [];
  bool _isLoading = true;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    final photos = await widget.dbService.getPhotos(limit: 100);
    final stats = await widget.syncService.getSyncStats();
    setState(() {
      _photos = photos;
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PhotoSync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await widget.syncService.startSync();
              _loadPhotos();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsBar(),
                Expanded(child: _buildPhotoGrid()),
              ],
            ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('总计', _stats['total'] ?? 0),
          _buildStat('已同步', _stats['synced'] ?? 0),
          _buildStat('待同步', _stats['pending'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(label),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    if (_photos.isEmpty) {
      return const Center(child: Text('暂无照片，点击同步按钮开始'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return _buildPhotoTile(photo);
      },
    );
  }

  Widget _buildPhotoTile(Photo photo) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          photo.devicePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image),
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: _buildSyncIcon(photo.syncStatus),
        ),
      ],
    );
  }

  Widget _buildSyncIcon(String status) {
    switch (status) {
      case 'synced':
        return const CircleAvatar(
          radius: 10,
          backgroundColor: Colors.green,
          child: Icon(Icons.check, size: 14, color: Colors.white),
        );
      case 'uploading':
        return const CircleAvatar(
          radius: 10,
          backgroundColor: Colors.blue,
          child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        );
      case 'failed':
        return const CircleAvatar(
          radius: 10,
          backgroundColor: Colors.red,
          child: Icon(Icons.error, size: 14, color: Colors.white),
        );
      default:
        return const CircleAvatar(
          radius: 10,
          backgroundColor: Colors.grey,
          child: Icon(Icons.cloud_upload, size: 14, color: Colors.white),
        );
    }
  }
}
