// lib/features/auth/domain/user_model.dart

class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? birthDate;
  final String? bio;
  final String? profilePictureUrl;
  final DateTime createdAt;
  final bool isVerified; // <-- Tambahkan ini

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.birthDate,
    this.bio,
    this.profilePictureUrl,
    required this.createdAt,
    required this.isVerified, // <-- Tambahkan ini
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? 'Tanpa Nama',
      username: json['username'] ?? '',
      email: json['email'],
      birthDate: json['birth_date'],
      bio: json['bio'],
      profilePictureUrl: json['profile_picture_path'],
      createdAt: DateTime.parse(json['createdAt']),
      isVerified: json['isVerified'] == 1, // <-- Tambahkan ini
    );
  }
}
