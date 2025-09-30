// lib/features/archive/application/archive_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/domain/models/topic_model.dart';
import 'package:my_aplication/features/settings/application/services/api_config_service.dart';
import 'package:my_aplication/features/auth/application/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ArchiveService {
  final ApiConfigService _apiConfigService = ApiConfigService();
  final AuthService _authService = AuthService();

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

  Future<String> _getDomain() async {
    final apiConfig = await _apiConfigService.loadConfig();
    final apiDomain = apiConfig['domain'];
    if (apiDomain == null || apiDomain.isEmpty) {
      throw Exception('Domain API tidak dikonfigurasi.');
    }
    return apiDomain;
  }

  // ==> PASTIKAN FUNGSI INI ADA DAN LENGKAP <==
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
      // Coba decode JSON untuk pesan error yang lebih baik
      try {
        final decoded = json.decode(responseBody);
        throw HttpException(decoded['message'] ?? 'Gagal mengunggah arsip.');
      } catch (e) {
        throw HttpException('Gagal mengunggah arsip: $responseBody');
      }
    }
    final responseBody = await response.stream.bytesToString();
    return json.decode(responseBody)['message'] ?? 'Arsip berhasil diunggah.';
  }

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

  Future<File> downloadArchivedFile(String relativePath) async {
    final domain = await _getDomain();
    final headers = await _getHeaders();

    final encodedPath = Uri.encodeComponent(relativePath);
    final uri = Uri.parse('$domain/api/archive/file?path=$encodedPath');

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(tempDir.path, path.basename(relativePath));
      final file = File(filePath);

      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(
        'Gagal mengunduh file: ${errorBody['message'] ?? response.reasonPhrase}',
      );
    }
  }
}
