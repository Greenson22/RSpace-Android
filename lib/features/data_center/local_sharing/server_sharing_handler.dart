// lib/features/data_center/presentation/widgets/server_sharing_handler.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/services/path_service.dart';

class ServerSharingHandler {
  final StorageService storageService;
  final PathService pathService;
  HttpServer? _serverEksternal;

  ServerSharingHandler({
    required this.storageService,
    required this.pathService,
  });

  void dispose() {
    _serverEksternal?.close(force: true);
  }

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

  Future<String> _getLocalIpAddress() async {
    try {
      List<NetworkInterface> interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          if (address.address.isNotEmpty) return address.address;
        }
      }
    } catch (e) {
      debugPrint("Gagal mendapatkan IP: $e");
    }
    return "Tidak Diketahui";
  }

  Future<void> startServerSharing({
    required BuildContext context,
    required String baseDir,
    required Function(bool) setLoading,
    required VoidCallback onRefresh,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menyiapkan server...'),
        backgroundColor: Colors.indigo,
      ),
    );

    try {
      String localIp = await _getLocalIpAddress();
      if (_serverEksternal != null) {
        await _serverEksternal!.close(force: true);
      }
      List<dynamic> clientActiveList = [];
      StateSetter? dialogState;

      // PERBAIKAN: Parameter disesuaikan kembali dengan dynamic webSocket & protocol asli shelf_web_socket
      var handler = webSocketHandler((dynamic webSocket, dynamic protocol) {
        clientActiveList.add(webSocket);
        if (dialogState != null) dialogState!(() {});

        webSocket.sink.add(jsonEncode({'tipe_pesan': 'koneksi_terkonfirmasi'}));

        webSocket.stream.listen(
          (pesanMasuk) async {
            try {
              Map<String, dynamic> data = jsonDecode(pesanMasuk);
              if (data['tipe_pesan'] == 'data_transfer' &&
                  data['full_backup_zip'] != null) {
                List<int> zipBytes = base64Decode(data['full_backup_zip']);
                String namaZip = _getFormattedFileName('client_backup', 'zip');
                File fileTarget = await storageService.getBackupZipFile(
                  baseDir,
                  namaZip,
                );
                await fileTarget.writeAsBytes(zipBytes);

                onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sukses menerima data: $namaZip'),
                    backgroundColor: Colors.teal,
                  ),
                );
              }
            } catch (err) {
              debugPrint("Server error: $err");
            }
          },
          onDone: () {
            clientActiveList.remove(webSocket);
            if (dialogState != null) dialogState!(() {});
          },
          onError: (_) {
            clientActiveList.remove(webSocket);
            if (dialogState != null) dialogState!(() {});
          },
        );
      });

      _serverEksternal = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        8090,
      );

      // PERBAIKAN: Mengembalikan fungsi pembubusan ZIP bawaan proyek awal Anda yang valid
      Future<void> sendDataToServer() async {
        if (clientActiveList.isEmpty) return;
        setLoading(true);
        try {
          final String appBasePath =
              await pathService.loadCustomStoragePath() ?? "";
          Directory rootDir = appBasePath.isNotEmpty
              ? Directory(appBasePath)
              : Directory(await pathService.profilePicturesPath).parent;

          String tempZipName = _getFormattedFileName('temp_server_send', 'zip');
          File tempZipFile = await storageService.createBackupZip(
            mainFolderPath: rootDir.path,
            baseDir: baseDir,
            fileName: tempZipName,
            isServerSharing: true,
          );

          List<int> zipBytes = await tempZipFile.readAsBytes();
          String base64Data = base64Encode(zipBytes);
          if (await tempZipFile.exists()) await tempZipFile.delete();

          String jsonPayload = jsonEncode({
            'tipe_pesan': 'data_transfer',
            'full_backup_zip': base64Data,
          });
          for (var socket in clientActiveList) {
            socket.sink.add(jsonPayload);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kirim data sukses!'),
              backgroundColor: Colors.teal,
            ),
          );
        } finally {
          setLoading(false);
        }
      }

      if (!context.mounted) return;

      // Tampilkan UI Dialog Server Modern Penuh Animasi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            dialogState = setDialogState;
            bool adaClient = clientActiveList.isNotEmpty;
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
                      color: Colors.indigo.withOpacity(0.15),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animasi Status Header Radar / Sukses
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: adaClient
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 72,
                              key: ValueKey('connected'),
                            )
                          : SizedBox(
                              key: const ValueKey('waiting'),
                              height: 72,
                              width: 72,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 64,
                                    width: 64,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.indigo.withOpacity(0.4),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.wifi_tethering_rounded,
                                    color: Colors.indigo,
                                    size: 36,
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Server Berbagi Aktif',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masukkan Alamat IP ini ke perangkat tujuan untuk menghubungkan kedua perangkat:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Box Informasi IP Server yang Bold dan Menarik
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.indigo.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lan_rounded,
                            color: Colors.indigo,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            localIp,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Indikator Real-time Jumlah Perangkat Terhubung
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: adaClient
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: adaClient
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            adaClient
                                ? Icons.devices_rounded
                                : Icons.hourglass_empty_rounded,
                            color: adaClient ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            adaClient
                                ? '${clientActiveList.length} Perangkat Terhubung'
                                : 'Menunggu Koneksi Perangkat...',
                            style: TextStyle(
                              color: adaClient
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Baris Tombol Kontrol Aksi
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                            onPressed: () async {
                              await _serverEksternal?.close(force: true);
                              _serverEksternal = null;
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: const Text(
                              'Matikan Server',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: adaClient ? 3 : 0,
                            ),
                            onPressed: adaClient
                                ? () => sendDataToServer()
                                : null,
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text(
                              'Kirim Data',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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
      ).then((_) => dialogState = null);
    } catch (e) {
      debugPrint("Gagal start server: $e");
    }
  }
}
