import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  final Dio _dio = Dio();
  String? _token;
  int? _userId;

  String? get token => _token;
  int? get userId => _userId;
  bool get isLoggedIn => _token != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userId = prefs.getInt('user_id');
  }

  Future<bool> register(String username, String password) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.apiBaseUrl}/auth/register',
        data: {'username': username, 'password': password},
      );
      if (response.data['code'] == 0) {
        _token = response.data['data']['token'];
        _userId = response.data['data']['user_id'];
        await _saveAuth();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.apiBaseUrl}/auth/login',
        data: {'username': username, 'password': password},
      );
      if (response.data['code'] == 0) {
        _token = response.data['data']['token'];
        _userId = response.data['data']['user_id'];
        await _saveAuth();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }

  Future<void> _saveAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setInt('user_id', _userId!);
  }

  Map<String, String> get authHeaders => {
    'Authorization': 'Bearer $_token',
  };
}
