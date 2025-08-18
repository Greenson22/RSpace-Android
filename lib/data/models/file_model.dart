// lib/data/models/file_model.dart

class FileItem {
  final String name;
  final String url;
  final int size;
  final String date;

  FileItem({
    required this.name,
    required this.url,
    required this.size,
    required this.date,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] ?? 'Untitled',
      url: json['url'] ?? '',
      size: json['size'] ?? 0,
      date: json['date'] ?? 'No Date',
    );
  }
}
