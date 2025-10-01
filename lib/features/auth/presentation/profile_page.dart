// lib/features/auth/presentation/profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../application/auth_provider.dart';
import 'login_page.dart';
import 'register_page.dart';
import '../domain/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Fungsi untuk memilih & mengunggah gambar
  Future<void> _pickAndUploadImage(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null && result.files.single.path != null) {
        final imageFile = File(result.files.single.path!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mengunggah foto profil...')),
        );

        await authProvider.uploadProfilePicture(imageFile);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        auth.checkLoginStatus();

        if (auth.authState == AuthState.authenticated) {
          return _buildLoggedInView(context, auth.user!);
        } else {
          return _buildGuestView(context);
        }
      },
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 60, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Anda belum login',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login atau buat akun untuk mengaktifkan fitur online seperti sinkronisasi dan backup.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  child: const Text('Buat Akun Baru'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context, User user) {
    final formattedDate = DateFormat(
      'd MMMM yyyy',
      'id_ID',
    ).format(user.createdAt);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileHeader(
            context,
            user,
            () => _pickAndUploadImage(context),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(context, [
            _buildInfoTile(Icons.email_outlined, 'Email', user.email),
            _buildInfoTile(
              Icons.cake_outlined,
              'Tanggal Lahir',
              user.birthDate ?? '-',
            ),
            _buildInfoTile(Icons.info_outline, 'Bio', user.bio ?? '-'),
            _buildInfoTile(
              Icons.calendar_today_outlined,
              'Bergabung Sejak',
              formattedDate,
            ),
          ]),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    User user,
    VoidCallback onEditPressed,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Column(
      children: [
        Stack(
          children: [
            FutureBuilder<String>(
              future: authProvider.authService.getApiDomain(),
              builder: (context, snapshot) {
                if (user.profilePictureUrl != null &&
                    snapshot.hasData &&
                    snapshot.data!.isNotEmpty) {
                  var domain = snapshot.data!;
                  // Hapus garis miring di akhir domain jika ada
                  if (domain.endsWith('/')) {
                    domain = domain.substring(0, domain.length - 1);
                  }

                  var relativePath = user.profilePictureUrl!;
                  // Hapus garis miring di awal path jika ada
                  if (relativePath.startsWith('/')) {
                    relativePath = relativePath.substring(1);
                  }

                  // Gabungkan dengan satu garis miring
                  final fullUrl =
                      '$domain/$relativePath?v=${DateTime.now().millisecondsSinceEpoch}';

                  return CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.2),
                    backgroundImage: NetworkImage(fullUrl),
                    onBackgroundImageError: (exception, stackTrace) {
                      debugPrint("Gagal memuat gambar profil: $exception");
                    },
                  );
                } else {
                  // Fallback jika tidak ada gambar atau domain belum siap
                  return _defaultAvatar(context, user);
                }
              },
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Material(
                color: Colors.grey.shade200,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onEditPressed,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.edit, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget _defaultAvatarContent(BuildContext context, User user) {
    return Text(
      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
      style: TextStyle(fontSize: 40, color: Theme.of(context).primaryColor),
    );
  }

  Widget _defaultAvatar(BuildContext context, User user) {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
      child: _defaultAvatarContent(context, user),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Card(child: Column(children: children));
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
