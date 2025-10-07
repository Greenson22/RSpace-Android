// lib/features/settings/presentation/dialogs/server_config_dialog.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart';
import 'package:my_aplication/features/settings/application/services/api_config_service.dart';

// Fungsi untuk menampilkan dialog
void showServerConfigDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const ServerConfigDialog(),
  );
}

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  final ApiConfigService _apiConfigService = ApiConfigService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _domainController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _domainController = TextEditingController();
    _loadConfig();
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    final config = await _apiConfigService.loadConfig();
    if (mounted) {
      setState(() {
        _domainController.text = config['domain'] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    String domain = _domainController.text.trim();
    if (domain.endsWith('/')) {
      domain = domain.substring(0, domain.length - 1);
    }

    // ==> PERUBAHAN DI SINI: Simpan string kosong untuk API Key <==
    await _apiConfigService.saveConfig(domain, '');

    if (mounted) {
      showAppSnackBar(context, 'Konfigurasi server berhasil disimpan.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfigurasi Server'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _domainController,
                      decoration: const InputDecoration(
                        labelText: 'Domain Server',
                        hintText: 'Contoh: http://192.168.1.5:3001',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Domain tidak boleh kosong.';
                        }
                        return null;
                      },
                    ),
                    // ==> TextFormField untuk API Key telah dihapus dari sini <==
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _saveConfig, child: const Text('Simpan')),
      ],
    );
  }
}
