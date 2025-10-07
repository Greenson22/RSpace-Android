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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Pengguna')),
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
                  child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
                ),
                title: Text(user.name),
                subtitle: Text('${user.email} - Bergabung: $formattedDate'),
                trailing: IconButton(
                  icon: const Icon(Icons.password),
                  tooltip: 'Ubah Password',
                  onPressed: () => _showChangePasswordDialog(context, user),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
