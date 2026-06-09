// lib/features/data_center/presentation/widgets/client_sharing_handler.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:my_aplication/features/content_management/topics/providers/topic_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/path_service.dart';

class ClientSharingHandler {
  final StorageService storageService;
  final PathService pathService;

  ClientSharingHandler({
    required this.storageService,
    required this.pathService,
  });

  String _getFormattedFileName(String prefix, String extension) {
    final now = DateTime.now();
    const daftarHari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    String namaHari = daftarHari[now.weekday - 1];
    String tanggal =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    String waktu =
        "${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";
    return "${prefix}_${tanggal}_${namaHari}_$waktu.$extension";
  }

  void showConnectDialog({
    required BuildContext context,
    required String baseDir,
    required Function(bool) setLoading,
    required VoidCallback onRefresh,
  }) async {
    List<String> ipHistory = await storageService.getIpHistory();
    final ipController = TextEditingController(
      text: ipHistory.isNotEmpty ? ipHistory.first : '',
    );

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Dialog yang Modern
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_to_home_screen_rounded,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Hubungkan ke Server',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Masukkan alamat IP Server dari perangkat utama yang mengaktifkan server berbagi data.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input Field Bergaya Outline Modern
                  TextField(
                    controller: ipController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'IP Server Target',
                      hintText: 'Contoh: 192.168.1.5',
                      prefixIcon: const Icon(
                        Icons.wifi_tethering_rounded,
                        size: 22,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Colors.indigo,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  // Riwayat IP dengan Card List modern
                  if (ipHistory.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: Colors.indigo.shade400,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Riwayat Alamat IP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: ipHistory.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (c, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 0,
                              ),
                              leading: const Icon(
                                Icons.lan_outlined,
                                color: Colors.grey,
                                size: 18,
                              ),
                              title: Text(
                                ipHistory[index],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  await storageService.deleteIpFromHistory(
                                    ipHistory[index],
                                  );
                                  setDialogState(
                                    () => ipHistory.removeAt(index),
                                  );
                                },
                              ),
                              onTap: () => setDialogState(
                                () => ipController.text = ipHistory[index],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // Baris Tombol Aksi Kustom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          String targetIp = ipController.text.trim();
                          if (targetIp.isNotEmpty) {
                            await storageService.saveIpToHistory(targetIp);
                            if (ctx.mounted) Navigator.pop(ctx);
                            _connectAndReceiveData(
                              context,
                              targetIp,
                              baseDir,
                              setLoading,
                              onRefresh,
                            );
                          }
                        },
                        icon: const Icon(Icons.link_rounded, size: 18),
                        label: const Text(
                          'Hubungkan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _connectAndReceiveData(
    BuildContext context,
    String ipAddress,
    String baseDir,
    Function(bool) setLoading,
    VoidCallback onRefresh,
  ) {
    final url = 'ws://$ipAddress:8090';
    setLoading(true);

    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      bool isConnected = true;
      StateSetter? clientDialogState;

      Future<void> sendDataToServer() async {
        if (!isConnected) return;
        setLoading(true);
        try {
          final appBasePath = await pathService.loadCustomStoragePath() ?? "";
          Directory rootDir = appBasePath.isNotEmpty
              ? Directory(appBasePath)
              : Directory(await pathService.profilePicturesPath).parent;

          String tempZipName = _getFormattedFileName('temp_client_send', 'zip');
          File tempZipFile = await storageService.createBackupZip(
            mainFolderPath: rootDir.path,
            baseDir: baseDir,
            fileName: tempZipName,
            isServerSharing: true,
          );

          List<int> zipBytes = await tempZipFile.readAsBytes();
          if (await tempZipFile.exists()) await tempZipFile.delete();

          channel.sink.add(
            jsonEncode({
              'tipe_pesan': 'data_transfer',
              'full_backup_zip': base64Encode(zipBytes),
            }),
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Data sukses dikirim!')));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          setLoading(false);
        }
      }

      // --- PERBAIKAN DIALOG KONEKSI: Tampilan Klien Beranimasi dan Responsif ---
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => StatefulBuilder(
            builder: (context, setDialogState) {
              clientDialogState = setDialogState;
              return Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isConnected
                            ? Colors.teal.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animasi Rotasi & Skala Status Sinkronisasi Koneksi
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: isConnected
                            ? const Icon(
                                Icons.cloud_sync_rounded,
                                color: Colors.teal,
                                size: 76,
                                key: ValueKey('connected_client'),
                              )
                            : const Icon(
                                Icons.cloud_off_rounded,
                                color: Colors.redAccent,
                                size: 76,
                                key: ValueKey('disconnected_client'),
                              ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isConnected
                            ? 'Terhubung Ke Server'
                            : 'Terputus dari Server',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isConnected
                              ? Colors.teal[800]
                              : Colors.red[800],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Badge IP Alamat Server
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.dns_rounded,
                              color: isConnected ? Colors.teal : Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              ipAddress,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Tombol Unggah Utama secara Full-Width
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isConnected ? sendDataToServer : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: isConnected ? 3 : 0,
                          ),
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text(
                            'Kirim Data Saya Ke Server',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tombol Putuskan Sesi
                      TextButton(
                        onPressed: () {
                          channel.sink.close();
                          Navigator.pop(ctx);
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        child: const Text(
                          'Putuskan & Tutup Dialog',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }

      channel.stream.listen(
        (pesan) async {
          setLoading(false);
          try {
            Map<String, dynamic> data = jsonDecode(pesan);

            if (data['tipe_pesan'] == 'koneksi_terkonfirmasi') {
              isConnected = true;
              if (clientDialogState != null) clientDialogState!(() {});
              return;
            }

            if (data['tipe_pesan'] == 'data_transfer' &&
                data['full_backup_zip'] != null) {
              List<int> zipBytes = base64Decode(data['full_backup_zip']);
              String namaZip = _getFormattedFileName('server_backup', 'zip');
              File targetFile = await storageService.getBackupZipFile(
                baseDir,
                namaZip,
              );
              await targetFile.writeAsBytes(zipBytes);

              if (context.mounted) {
                Provider.of<TopicProvider>(
                  context,
                  listen: false,
                ).fetchTopics();
              }
              onRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Berkas diterima dari Server!'),
                  backgroundColor: Colors.teal,
                ),
              );
            }
          } catch (e) {
            debugPrint("Client error parsing data: $e");
          }
        },
        onDone: () {
          setLoading(false);
          isConnected = false;
          if (clientDialogState != null) {
            clientDialogState!(() {});
          }
        },
        onError: (_) {
          setLoading(false);
          isConnected = false;
          if (clientDialogState != null) {
            clientDialogState!(() {});
          }
        },
      );
    } catch (e) {
      setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal koneksi!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
