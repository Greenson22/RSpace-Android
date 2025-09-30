// lib/features/auth/application/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:my_aplication/features/settings/application/services/api_config_service.dart';
import '../domain/user_model.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class AuthService {
  final ApiConfigService _apiConfigService = ApiConfigService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _tokenKey = 'rspace_token';

  // == PERUBAHAN DI SINI ==
  // Hapus garis bawah untuk menjadikan metode ini public
  Future<String> getApiDomain() async {
    final config = await _apiConfigService.loadConfig();
    final domain = config['domain'];
    if (domain == null || domain.isEmpty) {
      throw Exception('Domain API belum dikonfigurasi.');
    }
    return domain;
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> login(String email, String password) async {
    // Gunakan metode yang sudah public
    final domain = await getApiDomain();
    final response = await http.post(
      Uri.parse('$domain/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _secureStorage.write(key: _tokenKey, value: data['token']);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal login.');
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<void> register(String name, String email, String password) async {
    final domain = await getApiDomain();
    final response = await http.post(
      Uri.parse('$domain/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      final errorMessage =
          data['message'] ??
          (data['errors']?[0]?['msg'] ?? 'Gagal melakukan registrasi.');
      throw Exception(errorMessage);
    }
  }

  Future<User> getUserProfile() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Tidak terautentikasi.');
    }

    final domain = await getApiDomain();
    final response = await http.get(
      Uri.parse('$domain/api/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      if (response.statusCode == 400 || response.statusCode == 401) {
        await logout();
      }
      throw Exception('Gagal memuat profil.');
    }
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    final token = await getToken();
    if (token == null) throw Exception('Tidak terautentikasi.');

    final domain = await getApiDomain();
    final uri = Uri.parse('$domain/api/profile/picture');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'profilePicture',
        imageFile.path,
        contentType: MediaType(
          'image',
          path.extension(imageFile.path).substring(1),
        ),
      ),
    );

    final response = await request.send();

    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Gagal mengunggah foto: $responseBody');
    }
  }
}
