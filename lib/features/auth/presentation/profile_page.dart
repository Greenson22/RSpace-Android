// lib/features/auth/presentation/profile_page.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart';
import 'package:provider/provider.dart';
import '../application/auth_provider.dart';
import 'login_page.dart';
import 'register_page.dart';
import '../domain/user_model.dart';
import 'package:my_aplication/features/admin/presentation/pages/admin_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // State untuk timer kirim ulang
  Timer? _cooldownTimer;
  int _cooldownSeconds = 60;
  bool _canResend = true;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _canResend = false;
      _cooldownSeconds = 60;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        _cooldownTimer?.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _handleResend(String email) async {
    _startCooldown();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.resendVerification(email);
      if (mounted)
        showAppSnackBar(context, 'Email verifikasi baru telah dikirim.');
    } catch (e) {
      if (mounted) showAppSnackBar(context, e.toString(), isError: true);
    }
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null && result.files.single.path != null) {
        final imageFile = File(result.files.single.path!);

        showAppSnackBar(context, 'Mengunggah foto profil...');

        await authProvider.uploadProfilePicture(imageFile);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          showAppSnackBar(context, 'Foto profil berhasil diperbarui!');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showAppSnackBar(context, 'Gagal: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.authState == AuthState.uninitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.authState == AuthState.authenticated) {
          return _buildLoggedInView(context, auth);
        } else {
          return _buildGuestView(context);
        }
      },
    );
  }

  Widget _buildGuestView(BuildContext context) {
    // Tampilan ini tidak berubah
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

  Widget _buildLoggedInView(BuildContext context, AuthProvider auth) {
    final user = auth.user!;
    final formattedDate = DateFormat(
      'd MMMM yyyy',
      'id_ID',
    ).format(user.createdAt);
    final bool isAdmin = user.id == 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ==> TAMPILKAN BANNER PERINGATAN JIKA BELUM VERIFIKASI <==
          if (!user.isVerified) _buildVerificationWarning(context, user.email),

          _buildProfileHeader(
            context,
            auth,
            () => _pickAndUploadImage(context),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(context, [
            _buildInfoTile(Icons.person_outline, 'Username', user.username),
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
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPage()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Manajemen Pengguna'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
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

  // ==> WIDGET BARU UNTUK BANNER PERINGATAN <==
  Widget _buildVerificationWarning(BuildContext context, String email) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akun Belum Diverifikasi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Periksa email Anda atau kirim ulang link verifikasi.',
                  style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _canResend ? () => _handleResend(email) : null,
            child: Text(
              _canResend ? 'KIRIM ULANG' : 'Tunggu ($_cooldownSeconds s)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AuthProvider auth,
    VoidCallback onEditPressed,
  ) {
    // ... (Fungsi ini tidak berubah)
    final user = auth.user!;
    final localImage = auth.localProfilePicture;

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              backgroundImage: localImage != null
                  ? FileImage(localImage)
                  : null,
              child: auth.isProfilePictureLoading
                  ? const CircularProgressIndicator()
                  : localImage == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : null,
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

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    // ... (Fungsi ini tidak berubah)
    return Card(child: Column(children: children));
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    // ... (Fungsi ini tidak berubah)
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
