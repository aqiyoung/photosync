import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/local_db_service.dart';
import 'services/photo_service.dart';
import 'services/sync_service.dart';
import 'screens/login_screen.dart';
import 'screens/gallery_screen.dart';

class PhotoSyncApp extends StatefulWidget {
  const PhotoSyncApp({super.key});

  @override
  State<PhotoSyncApp> createState() => _PhotoSyncAppState();
}

class _PhotoSyncAppState extends State<PhotoSyncApp> {
  final _authService = AuthService();
  final _dbService = LocalDbService();
  final _photoService = PhotoService();
  late SyncService _syncService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _syncService = SyncService(_authService, _dbService, _photoService);
    _init();
  }

  Future<void> _init() async {
    await _authService.init();
    if (_authService.isLoggedIn) {
      _syncService.startSync();
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'PhotoSync',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: _authService.isLoggedIn
          ? GalleryScreen(dbService: _dbService, syncService: _syncService)
          : LoginScreen(
              authService: _authService,
              onLoginSuccess: () => setState(() {}),
            ),
    );
  }
}
