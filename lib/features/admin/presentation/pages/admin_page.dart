// lib/features/admin/presentation/pages/admin_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../application/admin_provider.dart';
import '../../domain/models/admin_user_model.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: const _AdminPageView(),
    );
  }
}

class _AdminPageView extends StatelessWidget {
  const _AdminPageView();

  void _showChangePasswordDialog(BuildContext context, AdminUser user) {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Ubah Password untuk ${user.name}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: passwordController,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Baru (min. 6 karakter)',
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password minimal 6 karakter.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final message = await provider.changePassword(
                      user.id,
                      passwordController.text,
                    );
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // ==> FUNGSI BARU UNTUK DIALOG VERIFIKASI <==
  void _showVerifyUserDialog(BuildContext context, AdminUser user) {
    final provider = Provider.of<AdminProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Verifikasi'),
        content: Text(
          'Anda yakin ingin memverifikasi akun "${user.email}" secara manual?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final message = await provider.verifyUser(user.id);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ya, Verifikasi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchUsers(),
            tooltip: 'Muat Ulang Daftar',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          if (provider.users.isEmpty) {
            return const Center(child: Text('Tidak ada pengguna lain.'));
          }
          return ListView.builder(
            itemCount: provider.users.length,
            itemBuilder: (context, index) {
              final user = provider.users[index];
              final formattedDate = DateFormat(
                'd MMM yyyy',
              ).format(user.createdAt);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: user.isVerified
                      ? Colors.green.withOpacity(0.2)
                      : Colors.amber.withOpacity(0.2),
                  child: Icon(
                    user.isVerified ? Icons.check : Icons.mail_outline,
                    color: user.isVerified
                        ? Colors.green
                        : Colors.amber.shade800,
                  ),
                ),
                title: Text(user.name),
                subtitle: Text('${user.email} - Bergabung: $formattedDate'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'change_password') {
                      _showChangePasswordDialog(context, user);
                    } else if (value == 'verify_manual') {
                      _showVerifyUserDialog(context, user);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'change_password',
                      child: Text('Ubah Password'),
                    ),
                    // Tampilkan opsi verifikasi hanya jika belum terverifikasi
                    if (!user.isVerified)
                      const PopupMenuItem(
                        value: 'verify_manual',
                        child: Text('Verifikasi Manual'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
