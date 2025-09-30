// lib/features/auth/presentation/profile_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/features/auth/application/auth_provider.dart';
import 'package:my_aplication/features/auth/domain/user_model.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Gagal memuat data pengguna.')),
      );
    }

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
