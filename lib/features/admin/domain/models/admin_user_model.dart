// lib/features/admin/domain/models/admin_user_model.dart
class AdminUser {
  final int id;
  final String name;
  final String email;
  final DateTime createdAt;
  final bool isVerified; // <-- Tambahkan ini

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.isVerified, // <-- Tambahkan ini
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      name: json['name'] ?? 'Tanpa Nama',
      email: json['email'],
      createdAt: DateTime.parse(json['createdAt']),
      isVerified:
          json['isVerified'] ==
          1, // <-- Tambahkan ini (konversi dari integer 0/1)
    );
  }
}
