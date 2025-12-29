// lib/features/settings/presentation/dialogs/server_config_dialog.dart

import 'dart:async';
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

  // Status scanning
  bool _isScanning = false;
  String _scanStatusMessage = '';

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
          // Jika kosong, coba auto-detect IP sendiri untuk kenyamanan awal
          _autoDetectLocalIp();
        }
        _isLoading = false;
      });
    }
  }

  bool _isLikelyLocalIp(String host) {
    return host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        host.startsWith('172.') ||
        host == 'localhost';
  }

  // Mendapatkan IP Perangkat sendiri (Self-IP)
  Future<String?> _getMyIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      // Prioritaskan 192.168.x.x
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.address.startsWith('192.168.')) {
            return addr.address;
          }
        }
      }
      // Fallback ke IP non-loopback lainnya
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal mendeteksi Self-IP: $e");
    }
    return null;
  }

  Future<void> _autoDetectLocalIp() async {
    final ip = await _getMyIp();
    if (ip != null && mounted) {
      setState(() {
        _ipController.text = ip;
      });
    }
  }

  // --- LOGIKA PEMINDAIAN JARINGAN (NETWORK SCAN) ---

  Future<void> _scanNetwork() async {
    final portText = _portController.text.trim();
    if (portText.isEmpty) {
      showAppSnackBar(context, 'Tentukan port terlebih dahulu (misal: 3000)');
      return;
    }
    final int port = int.tryParse(portText) ?? 3000;

    setState(() {
      _isScanning = true;
      _scanStatusMessage = 'Mendapatkan Subnet...';
    });

    try {
      // 1. Dapatkan IP sendiri untuk tahu Subnet-nya
      final myIp = await _getMyIp();
      if (myIp == null) {
        throw Exception("Tidak terhubung ke jaringan (WiFi/LAN).");
      }

      // 2. Tentukan Prefix Subnet (misal: 192.168.1)
      final lastDotIndex = myIp.lastIndexOf('.');
      final subnetPrefix = myIp.substring(0, lastDotIndex);

      setState(() {
        _scanStatusMessage = 'Memindai $subnetPrefix.1 - 255...';
      });

      // 3. Scan Parallel (1-255)
      final List<String> activeServers = [];
      final List<Future<void>> futures = [];

      // Batasi concurrency jika perlu, tapi 254 socket biasanya aman di mobile
      for (int i = 1; i < 255; i++) {
        final targetIp = '$subnetPrefix.$i';
        futures.add(
          _checkPort(targetIp, port).then((isActive) {
            if (isActive) {
              activeServers.add(targetIp);
            }
          }),
        );
      }

      // Tunggu semua selesai (timeout diatur di _checkPort)
      await Future.wait(futures);

      // Urutkan IP agar rapi
      activeServers.sort((a, b) {
        final lastA = int.parse(a.split('.').last);
        final lastB = int.parse(b.split('.').last);
        return lastA.compareTo(lastB);
      });

      if (!mounted) return;
      setState(() => _isScanning = false);

      // 4. Tampilkan Hasil
      if (activeServers.isEmpty) {
        showAppSnackBar(context, "Tidak ditemukan server aktif di port $port.");
      } else if (activeServers.length == 1) {
        // Jika cuma 1, langsung isi dan beritahu user
        _ipController.text = activeServers.first;
        showAppSnackBar(context, "Ditemukan server: ${activeServers.first}");
      } else {
        // Jika banyak, suruh user milih
        _showIpSelectionDialog(activeServers);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        showAppSnackBar(context, "Scan error: $e");
      }
    }
  }

  // Cek koneksi ke IP:Port tertentu (TCP Connect)
  Future<bool> _checkPort(String ip, int port) async {
    try {
      // Timeout pendek (500ms) agar scan cepat selesai
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(milliseconds: 500),
      );
      socket.destroy(); // Tutup koneksi jika berhasil
      return true;
    } catch (e) {
      return false;
    }
  }

  void _showIpSelectionDialog(List<String> ips) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pilih Server"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: ips.length,
              itemBuilder: (context, index) {
                final ip = ips[index];
                return ListTile(
                  leading: const Icon(Icons.computer),
                  title: Text(ip),
                  onTap: () {
                    setState(() {
                      _ipController.text = ip;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    String finalDomain = '';

    if (_isLocalMode) {
      final ip = _ipController.text.trim();
      final port = _portController.text.trim();
      finalDomain = 'http://$ip:$port';
    } else {
      finalDomain = _onlineDomainController.text.trim();
      if (finalDomain.endsWith('/')) {
        finalDomain = finalDomain.substring(0, finalDomain.length - 1);
      }
      if (!finalDomain.startsWith('http')) {
        finalDomain = 'https://$finalDomain';
      }
    }

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
                    // Mode Selection
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

                    if (_isLocalMode) _buildLocalForm() else _buildOnlineForm(),
                  ],
                ),
              ),
            ),
      actions: [
        if (_isScanning)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              _scanStatusMessage,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        TextButton(
          onPressed: _isScanning ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isScanning ? null : _saveConfig,
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _buildLocalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Server Lokal (LAN/Wi-Fi)",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            // Tombol Scan Network
            if (!_isScanning)
              InkWell(
                onTap: _scanNetwork,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.radar, size: 14, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        "Scan LAN",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
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
                  // Mengubah suffix icon menjadi opsi deteksi IP sendiri
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location),
                    tooltip: "Gunakan IP Perangkat Ini (Self)",
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
