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
          return AlertDialog(
            title: const Text('Hubungkan ke Server'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ipController,
                  decoration: const InputDecoration(labelText: 'IP Server'),
                ),
                if (ipHistory.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: ipHistory.length,
                      itemBuilder: (c, index) {
                        return ListTile(
                          title: Text(ipHistory[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await storageService.deleteIpFromHistory(
                                ipHistory[index],
                              );
                              setDialogState(() => ipHistory.removeAt(index));
                            },
                          ),
                          onTap: () => setDialogState(
                            () => ipController.text = ipHistory[index],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
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
                child: const Text('Hubungkan'),
              ),
            ],
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
      bool isDialogOpened = false;
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
        } finally {
          setLoading(false);
        }
      }

      channel.stream.listen(
        (pesan) async {
          setLoading(false);
          try {
            Map<String, dynamic> data = jsonDecode(pesan);
            if (data['tipe_pesan'] == 'data_transfer' &&
                data['full_backup_zip'] != null) {
              List<int> zipBytes = base64Decode(data['full_backup_zip']);
              String namaZip = _getFormattedFileName('server_backup', 'zip');
              File targetFile = await storageService.getBackupZipFile(
                baseDir,
                namaZip,
              );
              await targetFile.writeAsBytes(zipBytes);

              if (context.mounted)
                Provider.of<TopicProvider>(
                  context,
                  listen: false,
                ).fetchTopics();
              onRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Berkas diterima dari Server!')),
              );
            }
          } catch (e) {
            debugPrint("Client error parsing data: $e");
          }

          if (!isDialogOpened && context.mounted) {
            isDialogOpened = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => StatefulBuilder(
                builder: (context, setDialogState) {
                  clientDialogState = setDialogState;
                  return AlertDialog(
                    title: Text(isConnected ? 'Terhubung' : 'Terputus'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('IP: $ipAddress'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: isConnected ? sendDataToServer : null,
                          child: const Text('Kirim Data Saya Ke Server'),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          channel.sink.close();
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Tutup',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ).then((_) => isDialogOpened = false);
          }
        },
        onDone: () {
          setLoading(false);
          isConnected = false;
          clientDialogState?.call(() {});
        },
        onError: (_) {
          setLoading(false);
          isConnected = false;
          clientDialogState?.call(() {});
        },
      );
    } catch (e) {
      setLoading(false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal koneksi!')));
    }
  }
}
