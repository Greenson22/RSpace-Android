// lib/features/settings/presentation/dialogs/server_config_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Controller untuk Mode Online
  late TextEditingController _onlineDomainController;

  // Controller untuk Mode Lokal
  late TextEditingController _ipController;
  late TextEditingController _portController;

  bool _isLoading = true;
  bool _isLocalMode = true; // Default ke mode lokal

  @override
  void initState() {
    super.initState();
    _onlineDomainController = TextEditingController();
    _ipController = TextEditingController();
    _portController = TextEditingController(text: '3000'); // Default port umum
    _loadConfig();
  }

  @override
  void dispose() {
    _onlineDomainController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    final config = await _apiConfigService.loadConfig();

    if (mounted) {
      final savedDomain = config['domain'] ?? '';

      setState(() {
        if (savedDomain.isNotEmpty) {
          // Analisa apakah domain ini terlihat seperti IP lokal
          final uri = Uri.tryParse(savedDomain);
          if (uri != null && _isLikelyLocalIp(uri.host)) {
            _isLocalMode = true;
            _ipController.text = uri.host;
            if (uri.hasPort) {
              _portController.text = uri.port.toString();
            }
          } else {
            _isLocalMode = false;
            _onlineDomainController.text = savedDomain;
          }
        } else {
          // Jika kosong, coba auto-detect IP untuk kenyamanan awal
          _autoDetectLocalIp();
        }
        _isLoading = false;
      });
    }
  }

  // Helper sederhana untuk mengecek apakah host terlihat seperti IP lokal
  bool _isLikelyLocalIp(String host) {
    return host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        host.startsWith('172.') ||
        host == 'localhost';
  }

  Future<void> _autoDetectLocalIp() async {
    try {
      // Mencari interface jaringan yang aktif
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Prioritaskan 192.168.x.x karena paling umum untuk Wi-Fi rumah
          if (addr.address.startsWith('192.168.')) {
            if (mounted) {
              setState(() {
                _ipController.text = addr.address;
              });
            }
            return;
          }
        }
      }

      // Jika tidak ketemu 192.168, ambil IP pertama yang bukan loopback
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            if (mounted) {
              setState(() {
                _ipController.text = addr.address;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal mendeteksi IP: $e");
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    String finalDomain = '';

    if (_isLocalMode) {
      final ip = _ipController.text.trim();
      final port = _portController.text.trim();
      // Konstruksi URL Lokal: http://[IP]:[PORT]
      finalDomain = 'http://$ip:$port';
    } else {
      finalDomain = _onlineDomainController.text.trim();
      // Pastikan tidak diakhiri slash untuk konsistensi
      if (finalDomain.endsWith('/')) {
        finalDomain = finalDomain.substring(0, finalDomain.length - 1);
      }
      // Tambahkan protokol jika lupa diketik user
      if (!finalDomain.startsWith('http')) {
        finalDomain = 'https://$finalDomain';
      }
    }

    // Simpan konfigurasi (apiKey dikosongkan sesuai permintaan sebelumnya)
    await _apiConfigService.saveConfig(finalDomain, '');

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
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pilihan Mode: Lokal vs Online
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Lokal'),
                            value: true,
                            groupValue: _isLocalMode,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setState(() {
                                _isLocalMode = val!;
                                if (_ipController.text.isEmpty) {
                                  _autoDetectLocalIp();
                                }
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Online'),
                            value: false,
                            groupValue: _isLocalMode,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) =>
                                setState(() => _isLocalMode = val!),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Form Input Dinamis
                    if (_isLocalMode) _buildLocalForm() else _buildOnlineForm(),
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

  Widget _buildLocalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Server Lokal (LAN/Wi-Fi)",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _ipController,
                decoration: InputDecoration(
                  labelText: 'IP Address',
                  hintText: '192.168.1.x',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.wifi_find),
                    tooltip: "Auto-detect IP Saya",
                    onPressed: _autoDetectLocalIp,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'IP Wajib diisi';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '3000',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Port Kosong';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Preview: http://${_ipController.text.isEmpty ? '...' : _ipController.text}:${_portController.text.isEmpty ? '...' : _portController.text}",
          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildOnlineForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Server Online (Domain Publik)",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _onlineDomainController,
          decoration: const InputDecoration(
            labelText: 'URL Domain',
            hintText: 'https://api.websiteku.com',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.language),
          ),
          keyboardType: TextInputType.url,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Domain tidak boleh kosong.';
            }
            return null;
          },
        ),
      ],
    );
  }
}
