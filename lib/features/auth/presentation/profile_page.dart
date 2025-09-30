// lib/features/auth/presentation/profile_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../application/auth_provider.dart';
import 'login_page.dart';
import 'register_page.dart';
import '../domain/user_model.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Cek status secara berkala saat halaman ini dibuka
        auth.checkLoginStatus();

        if (auth.authState == AuthState.authenticated) {
          return _buildLoggedInView(context, auth.user!);
        } else {
          return _buildGuestView(context);
        }
      },
    );
  }

  // Widget untuk tampilan saat belum login
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
                'Login atau buat akun untuk mengaktifkan fitur online seperti sinkronisasi dan backup data.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigasi ke halaman login dan tunggu hasilnya
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

  // Widget untuk tampilan saat sudah login
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
          _buildProfileHeader(context, user),
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
              // Cukup panggil logout, UI akan otomatis rebuild
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

  // Method lainnya ( _buildProfileHeader, _buildInfoCard, _buildInfoTile) tetap sama
  // ...
  Widget _buildProfileHeader(BuildContext context, User user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: TextStyle(
              fontSize: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
      ],
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
