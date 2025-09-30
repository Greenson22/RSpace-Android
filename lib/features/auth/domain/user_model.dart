// lib/features/auth/domain/user_model.dart

class User {
  final int id;
  final String name;
  final String email;
  final String? birthDate;
  final String? bio;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.birthDate,
    this.bio,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? 'Tanpa Nama',
      email: json['email'],
      birthDate: json['birth_date'],
      bio: json['bio'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
