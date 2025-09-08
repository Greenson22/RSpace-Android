// lib/data/models/file_model.dart

class FileItem {
  final String uniqueName;
  final String originalName;
  final String uploadedAt;
  final String downloadUrl; // Menggunakan URL download dari API

  FileItem({
    required this.uniqueName,
    required this.originalName,
    required this.uploadedAt,
    required this.downloadUrl,
  });

  factory FileItem.fromJson(Map<String, dynamic> json, String downloadBaseUrl) {
    final uniqueName = json['uniqueName'] ?? '';
    return FileItem(
      uniqueName: uniqueName,
      originalName: json['originalName'] ?? 'Untitled',
      uploadedAt: json['uploadedAt'] ?? 'No Date',
      // Menggabungkan base URL download dengan nama unik file
      downloadUrl: '$downloadBaseUrl$uniqueName',
    );
  }
}
