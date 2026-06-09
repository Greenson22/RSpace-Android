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

      var handler = webSocketHandler((dynamic webSocket, dynamic protocol) {
        final String clientId =
            "Client_${webSocket.hashCode.toString().substring(0, 4)}";
        clientActiveList.add(webSocket);
        if (dialogState != null) dialogState!(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('[$clientId] Terhubung!'),
            backgroundColor: Colors.green[800],
          ),
        );

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
      // Tampilkan UI Dialog Server
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            dialogState = setDialogState;
            bool adaClient = clientActiveList.isNotEmpty;
            return AlertDialog(
              title: const Text('Server Active'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'IP Server: $localIp',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    adaClient
                        ? 'Client Terhubung: ${clientActiveList.length}'
                        : 'Menunggu Perangkat...',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: adaClient ? () => sendDataToServer() : null,
                    child: const Text('Kirim Data Ke Client'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _serverEksternal?.close(force: true);
                    _serverEksternal = null;
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Matikan Server',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ),
      ).then((_) => dialogState = null);
    } catch (e) {
      debugPrint("Gagal start server: $e");
    }
  }
}
