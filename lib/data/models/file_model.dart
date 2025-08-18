// lib/data/models/file_model.dart

class FileItem {
  final String uniqueName;
  final String originalName;
  final String uploadedAt;
  final String url; // URL untuk mendownload file

  FileItem({
    required this.uniqueName,
    required this.originalName,
    required this.uploadedAt,
    required this.url,
  });

  // Factory constructor diperbarui untuk parsing JSON baru
  factory FileItem.fromJson(Map<String, dynamic> json, String baseUrl) {
    final uniqueName = json['uniqueName'] ?? '';
    return FileItem(
      uniqueName: uniqueName,
      originalName: json['originalName'] ?? 'Untitled',
      uploadedAt: json['uploadedAt'] ?? 'No Date',
      // Menggabungkan base URL dengan nama unik untuk membuat link download
      url: '$baseUrl/$uniqueName',
    );
  }
}
