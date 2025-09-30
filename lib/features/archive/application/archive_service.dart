// lib/features/archive/application/archive_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/domain/models/topic_model.dart';
import 'package:my_aplication/features/settings/application/services/api_config_service.dart';
// ==> 1. IMPORT AUTH SERVICE <==
import 'package:my_aplication/features/auth/application/auth_service.dart';

class ArchiveService {
  final ApiConfigService _apiConfigService = ApiConfigService();
  // ==> 2. BUAT INSTANCE DARI AUTH SERVICE <==
  final AuthService _authService = AuthService();

  // ==> 3. UBAH _getHeaders MENJADI FUNGSI DINAMIS <==
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Akses ditolak. Silakan login terlebih dahulu.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fungsi _getDomain tidak perlu diubah
  Future<String> _getDomain() async {
    final apiConfig = await _apiConfigService.loadConfig();
    final apiDomain = apiConfig['domain'];
    if (apiDomain == null || apiDomain.isEmpty) {
      throw Exception('Domain API tidak dikonfigurasi.');
    }
    return apiDomain;
  }

  // ==> 4. PERBARUI FUNGSI UPLOAD UNTUK MENGGUNAKAN TOKEN <==
  Future<String> uploadArchive(File archiveFile) async {
    final domain = await _getDomain();
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Akses ditolak. Silakan login terlebih dahulu.');
    }

    final url = '$domain/api/archive/discussions';
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath('zipfile', archiveFile.path),
    );

    final response = await request.send();

    if (response.statusCode != 201 && response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw HttpException('Gagal mengunggah: $responseBody');
    }
    final responseBody = await response.stream.bytesToString();
    return json.decode(responseBody)['message'] ?? 'Arsip berhasil diunggah.';
  }

  // ==> 5. PERBARUI SEMUA FUNGSI FETCH UNTUK MENGGUNAKAN _getHeaders() <==
  Future<List<Topic>> fetchArchivedTopics() async {
    final domain = await _getDomain();
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$domain/api/archive/topics'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Topic.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat topik arsip: ${response.body}');
    }
  }

  Future<List<Subject>> fetchArchivedSubjects(String topicName) async {
    final domain = await _getDomain();
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$domain/api/archive/topics/$topicName/subjects'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map(
            (item) =>
                Subject.fromJson(topicName, item['name'], {'metadata': item}),
          )
          .toList();
    } else {
      throw Exception('Gagal memuat subjek arsip: ${response.body}');
    }
  }

  Future<List<Discussion>> fetchArchivedDiscussions(
    String topicName,
    String subjectName,
  ) async {
    final domain = await _getDomain();
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse(
        '$domain/api/archive/topics/$topicName/subjects/$subjectName/discussions',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Discussion.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat diskusi arsip: ${response.body}');
    }
  }
}
