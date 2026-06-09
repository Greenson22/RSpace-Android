// lib/features/data_center/presentation/widgets/local_sharing_tab.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:my_aplication/features/content_management/topics/providers/topic_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/path_service.dart';

class LocalSharingTab extends StatefulWidget {
  const LocalSharingTab({super.key});

  @override
  State<LocalSharingTab> createState() => _LocalSharingTabState();
}

class _LocalSharingTabState extends State<LocalSharingTab> {
  final StorageService _storageService = StorageService();
  final PathService _pathService = PathService();

  String _baseDir = 'Documents';
  HttpServer? _serverEksternal;
  List<File> _serverBackupFiles = [];
  bool _isLoading = false;
  bool _isServerSelectionMode = false;
  final List<File> _selectedServerFiles = [];

  @override
  void initState() {
    super.initState();
    _loadBaseDirectory();
  }

  @override
  void dispose() {
    _serverEksternal?.close(force: true);
    super.dispose();
  }

  // --- LOGIKA MANAJEMEN MEMORI & BERKAS SERVER ---
  Future<void> _loadBaseDirectory() async {
    String dir = await _storageService.getBaseDirSetting();
    if (mounted) {
      setState(() {
        _baseDir = dir;
      });
      _loadServerBackups();
    }
  }

  Future<void> _loadServerBackups() async {
    List<File> files = await _storageService.getAllServerBackupFiles(_baseDir);
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    setState(() {
      _serverBackupFiles = files;
    });
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
      debugPrint("Gagal mendapatkan alamat IP: $e");
    }
    return "Tidak Diketahui";
  }

  // --- LOGIKA UTAMA: RESTORE DATA DARI ZIP ---
  void _importAllFromZip(File zipFile) async {
    setState(() => _isLoading = true);
    try {
      final String appBasePath =
          await _pathService.loadCustomStoragePath() ?? "";
      Directory rootDir = appBasePath.isNotEmpty
          ? Directory(appBasePath)
          : Directory(await _pathService.profilePicturesPath).parent;
      final String destinationPath = rootDir.path;

      // 1. PENERAPAN PENGHAPUSAN BERSIH SEBELUM RESTORE
      // Mencari folder aktif saat ini (bisa langsung di root atau di dalam folder 'data')
      Directory activeRSpaceDir = Directory(
        path.join(destinationPath, 'RSpace_data'),
      );
      if (!activeRSpaceDir.existsSync()) {
        activeRSpaceDir = Directory(
          path.join(destinationPath, 'data', 'RSpace_data'),
        );
      }

      final Directory activePerpuskuDir = Directory(
        path.join(destinationPath, 'PerpusKu'),
      );

      if (activeRSpaceDir.existsSync()) {
        await activeRSpaceDir.delete(recursive: true);
      }
      if (activePerpuskuDir.existsSync()) {
        await activePerpuskuDir.delete(recursive: true);
      }

      // 2. PROSES EKSTRAKSI DATA BARU
      List<int> bytes = await zipFile.readAsBytes();
      Archive archive = ZipDecoder().decodeBytes(bytes);
      for (ArchiveFile file in archive) {
        String targetFolder = destinationPath;

        // Jika saat ZIP dibuat foldernya murni berawalan 'RSpace_data', kembalikan ke struktur aslinya
        if (appBasePath.isEmpty && file.name.startsWith('RSpace_data')) {
          targetFolder = path.join(destinationPath, 'data');
        }

        String fullPathTarget = path.join(targetFolder, file.name);
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(fullPathTarget);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
        } else {
          final outDir = Directory(fullPathTarget);
          await outDir.create(recursive: true);
        }
      }

      if (mounted) {
        Provider.of<TopicProvider>(context, listen: false).fetchTopics();
      }
      setState(() {
        _loadServerBackups();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore Berhasil! Berkas disinkronkan dari "${zipFile.path.split('/').last}".',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      debugPrint("Gagal mengimpor file ZIP ke folder utama: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal melakukan restore: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA JARINGAN: AKTIFKAN SERVER SHARING (PENGIRIM) ---
  void _startServerSharing() async {
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menyiapkan server komunikasi dua arah...'),
          backgroundColor: Colors.indigo,
        ),
      );
    });
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
        setState(() {
          clientActiveList.add(webSocket);
        });
        if (dialogState != null) dialogState!(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('  [$clientId] Berhasil Terhubung ke Server!'),
            backgroundColor: Colors.green[800],
            duration: const Duration(seconds: 3),
          ),
        );

        Map<String, dynamic> openingMessage = {
          'tipe_pesan': 'koneksi_terkonfirmasi',
        };
        webSocket.sink.add(jsonEncode(openingMessage));

        webSocket.stream.listen(
          (pesanMasuk) async {
            try {
              Map<String, dynamic> dateReceived = jsonDecode(pesanMasuk);
              if (dateReceived['tipe_pesan'] == 'data_transfer') {
                String? clientFullZipBase64 = dateReceived['full_backup_zip'];

                if (clientFullZipBase64 != null &&
                    clientFullZipBase64.isNotEmpty) {
                  List<int> zipBytes = base64Decode(clientFullZipBase64);

                  String namaZipDinamis = _getFormattedFileName(
                    'client_backup',
                    'zip',
                  );
                  File fileZipTarget = await _storageService.getBackupZipFile(
                    _baseDir,
                    namaZipDinamis,
                  );
                  await fileZipTarget.writeAsBytes(zipBytes);

                  setState(() {
                    _loadServerBackups();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sukses menerima data dari Client! Tersimpan: $namaZipDinamis',
                      ),
                      backgroundColor: Colors.teal,
                    ),
                  );
                } else {
                  debugPrint("Server menerima paket data kosong.");
                }
              }
            } catch (err) {
              debugPrint("Server gagal memproses pesan: $err");
            }
          },
          onDone: () {
            setState(() {
              clientActiveList.remove(webSocket);
            });
            if (dialogState != null) dialogState!(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '  [$clientId] Koneksi Terputus atau Tiba-tiba Hilang.',
                ),
                backgroundColor: Colors.red[700],
                duration: const Duration(seconds: 4),
              ),
            );
          },
          onError: (error) {
            setState(() {
              clientActiveList.remove(webSocket);
            });
            if (dialogState != null) dialogState!(() {});
          },
        );
      });

      _serverEksternal = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        8090,
      );
      if (!mounted) return;

      Future<void> sendDataToServer() async {
        if (clientActiveList.isEmpty) return;

        setState(() => _isLoading = true);

        try {
          final String appBasePath =
              await _pathService.loadCustomStoragePath() ?? "";
          Directory rootDir;
          if (appBasePath.isNotEmpty) {
            rootDir = Directory(appBasePath);
          } else {
            final String profilePath = await _pathService.profilePicturesPath;
            rootDir = Directory(profilePath).parent;
          }
          final String mainFolderPath = rootDir.path;

          // ⚠️ PERBAIKAN UTAMA: Validasi Fallback Multi Jalur untuk RSpace_data
          Directory rspaceDir = Directory(
            path.join(mainFolderPath, 'RSpace_data'),
          );
          if (!rspaceDir.existsSync()) {
            // Jika tidak ditemukan di root folder utama, cek di dalam subfolder 'data'
            rspaceDir = Directory(
              path.join(mainFolderPath, 'data', 'RSpace_data'),
            );
          }

          final Directory perpuskuDir = Directory(
            path.join(mainFolderPath, 'PerpusKu'),
          );

          final encoder = ZipFileEncoder();
          String tempZipName = _getFormattedFileName('temp_server_send', 'zip');
          File tempZipFile = await _storageService.getBackupZipFile(
            _baseDir,
            tempZipName,
          );

          encoder.create(tempZipFile.path);

          if (rspaceDir.existsSync()) {
            debugPrint(
              "=== ZIP SERVER: Menambahkan RSpace_data dari ${rspaceDir.path} ===",
            );
            await encoder.addDirectory(rspaceDir, includeDirName: true);
          } else {
            debugPrint(
              "=== ZIP SERVER: PERINGATAN! RSpace_data tidak ditemukan ===",
            );
          }

          if (perpuskuDir.existsSync()) {
            debugPrint(
              "=== ZIP SERVER: Menambahkan PerpusKu dari ${perpuskuDir.path} ===",
            );
            await encoder.addDirectory(perpuskuDir, includeDirName: true);
          }
          encoder.close();

          List<int> zipBytes = await tempZipFile.readAsBytes();
          String fullZipBase64 = base64Encode(zipBytes);

          if (await tempZipFile.exists()) {
            await tempZipFile.delete();
          }

          Map<String, dynamic> sendBigPackage = {
            'tipe_pesan': 'data_transfer',
            'full_backup_zip': fullZipBase64,
          };

          for (var socket in clientActiveList) {
            socket.sink.add(jsonEncode(sendBigPackage));
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Berhasil mengirim data ke ${clientActiveList.length} Client!',
              ),
              backgroundColor: Colors.teal,
            ),
          );
        } catch (e) {
          debugPrint("Server gagal membuat/mengirim paket: $e");
        } finally {
          setState(() => _isLoading = false);
        }
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            dialogState = setDialogState;
            bool adaClient = clientActiveList.isNotEmpty;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.wifi_tethering, color: Colors.indigo[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Server Sharing Active',
                    style: TextStyle(
                      color: Colors.indigo[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masukkan IP ini di perangkat Penerima:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localIp,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: adaClient
                          ? Colors.green.shade50
                          : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: adaClient
                            ? Colors.green.shade200
                            : Colors.amber.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          adaClient
                              ? Icons.gpp_good_rounded
                              : Icons.hourglass_empty_rounded,
                          color: adaClient
                              ? Colors.green[800]
                              : Colors.amber[800],
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            adaClient
                                ? 'Client Terhubung Aktif'
                                : 'Menunggu Perangkat...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: adaClient
                                  ? Colors.green[900]
                                  : Colors.amber[900],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: adaClient
                                ? Colors.green[700]
                                : Colors.amber[700],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${clientActiveList.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    adaClient
                        ? 'Silakan tekan tombol di bawah jika Anda ingin mendistribusikan data lokal ke perangkat yang terhubung.'
                        : 'Server siap menerima koneksi pipa baru secara lokal dari aplikasi client.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: adaClient ? () => sendDataToServer() : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[200],
                        disabledForegroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.send_and_archive),
                      label: const Text(
                        'Kirim Data Ke Client',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (_serverEksternal != null) {
                      await _serverEksternal!.close(force: true);
                      _serverEksternal = null;
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Matikan Server',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ).then((_) {
        dialogState = null;
      });
    } catch (e) {
      debugPrint("Gagal menyiapkan server dua arah: $e");
    }
  }

  // --- LOGIKA JARINGAN: HUBUNGKAN & AMBIL DATA (CLIENT/PENERIMA) ---
  void _showConnectToServerDialog() async {
    List<String> ipHistory = await _storageService.getIpHistory();
    final ipController = TextEditingController(
      text: ipHistory.isNotEmpty ? ipHistory.first : '',
    );
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Hubungkan ke Server'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ipController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat IP Server Pengirim',
                    hintText: 'Contoh: 192.168.1.5',
                  ),
                ),
                if (ipHistory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'IP yang pernah digunakan:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 120,
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: ipHistory.length,
                      itemBuilder: (c, index) {
                        final savedIp = ipHistory[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.history, size: 18),
                          title: Text(savedIp),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () async {
                              await _storageService.deleteIpFromHistory(
                                savedIp,
                              );
                              setDialogState(() {
                                ipHistory.remove(savedIp);
                                if (ipController.text == savedIp)
                                  ipController.clear();
                              });
                            },
                          ),
                          onTap: () {
                            setDialogState(() {
                              ipController.text = savedIp;
                            });
                          },
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
                    await _storageService.saveIpToHistory(targetIp);
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _receiveDateFromServerProcess(targetIp);
                  }
                },
                child: const Text('Hubungkan & Ambil'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _receiveDateFromServerProcess(String alamatIP) async {
    final urlWebSocket = 'ws://$alamatIP:8090';
    setState(() {
      _isLoading = true;
    });

    try {
      final channel = WebSocketChannel.connect(Uri.parse(urlWebSocket));
      bool isDialogOpened = false;
      bool isStillConnected = true;
      StateSetter? clientDialogState;

      Future<void> fungsiKirimDataClient() async {
        if (!isStillConnected) return;

        setState(() => _isLoading = true);

        try {
          final String appBasePath =
              await _pathService.loadCustomStoragePath() ?? "";
          Directory rootDir;
          if (appBasePath.isNotEmpty) {
            rootDir = Directory(appBasePath);
          } else {
            final String profilePath = await _pathService.profilePicturesPath;
            rootDir = Directory(profilePath).parent;
          }
          final String mainFolderPath = rootDir.path;

          // ⚠️ PERBAIKAN UTAMA: Validasi Fallback Multi Jalur untuk RSpace_data di Client
          Directory rspaceDir = Directory(
            path.join(mainFolderPath, 'RSpace_data'),
          );
          if (!rspaceDir.existsSync()) {
            rspaceDir = Directory(
              path.join(mainFolderPath, 'data', 'RSpace_data'),
            );
          }

          final Directory perpuskuDir = Directory(
            path.join(mainFolderPath, 'PerpusKu'),
          );

          final encoder = ZipFileEncoder();
          String tempZipName = _getFormattedFileName('temp_client_send', 'zip');
          File tempZipFile = await _storageService.getBackupZipFile(
            _baseDir,
            tempZipName,
          );

          encoder.create(tempZipFile.path);

          if (rspaceDir.existsSync()) {
            debugPrint(
              "=== ZIP CLIENT: Menambahkan RSpace_data dari ${rspaceDir.path} ===",
            );
            await encoder.addDirectory(rspaceDir, includeDirName: true);
          } else {
            debugPrint(
              "=== ZIP CLIENT: PERINGATAN! RSpace_data tidak ditemukan ===",
            );
          }

          if (perpuskuDir.existsSync()) {
            debugPrint(
              "=== ZIP CLIENT: Menambahkan PerpusKu dari ${perpuskuDir.path} ===",
            );
            await encoder.addDirectory(perpuskuDir, includeDirName: true);
          }
          encoder.close();

          List<int> zipBytes = await tempZipFile.readAsBytes();
          String fullZipBase64 = base64Encode(zipBytes);

          if (await tempZipFile.exists()) {
            await tempZipFile.delete();
          }

          Map<String, dynamic> paketBesarClient = {
            'tipe_pesan': 'data_transfer',
            'full_backup_zip': fullZipBase64,
          };

          channel.sink.add(jsonEncode(paketBesarClient));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data Anda sukses dikirimkan ke Server!'),
              backgroundColor: Colors.teal,
            ),
          );
        } catch (e) {
          debugPrint("Client gagal membuat/mengirim paket: $e");
        } finally {
          setState(() => _isLoading = false);
        }
      }

      channel.stream
          .timeout(
            const Duration(seconds: 45),
            onTimeout: (sink) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Batas waktu habis! Perangkat di $alamatIP tidak merespons.',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
              channel.sink.close();
              sink.close();
            },
          )
          .listen(
            (pesanMasuk) async {
              if (_isLoading) {
                setState(() {
                  _isLoading = false;
                });
              }
              try {
                Map<String, dynamic> dataDiterima = jsonDecode(pesanMasuk);
                if (dataDiterima['tipe_pesan'] == 'koneksi_terkonfirmasi') {
                  debugPrint("Jabat tangan sukses. Pipa data penerima stabil.");
                }
                if (dataDiterima['tipe_pesan'] == 'data_transfer') {
                  String? serverFullZipBase64 = dataDiterima['full_backup_zip'];

                  if (serverFullZipBase64 != null &&
                      serverFullZipBase64.isNotEmpty) {
                    List<int> zipBytes = base64Decode(serverFullZipBase64);

                    String namaZipDinamis = _getFormattedFileName(
                      'server_backup',
                      'zip',
                    );
                    File fileZipTarget = await _storageService.getBackupZipFile(
                      _baseDir,
                      namaZipDinamis,
                    );
                    await fileZipTarget.writeAsBytes(zipBytes);

                    if (mounted) {
                      Provider.of<TopicProvider>(
                        context,
                        listen: false,
                      ).fetchTopics();
                    }
                    setState(() {
                      _loadServerBackups();
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Sukses menerima berkas dari Server! Disimpan: $namaZipDinamis',
                        ),
                        backgroundColor: Colors.teal,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } else {
                    debugPrint("Client menerima paket data kosong.");
                  }
                }
              } catch (e) {
                debugPrint("Client gagal memproses data: $e");
              }

              if (!isDialogOpened && mounted) {
                isDialogOpened = true;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => StatefulBuilder(
                    builder: (context, setDialogState) {
                      clientDialogState = setDialogState;
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              isStillConnected
                                  ? Icons.cloud_done
                                  : Icons.cloud_off,
                              color: isStillConnected
                                  ? Colors.teal
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isStillConnected
                                  ? 'Terhubung ke Server'
                                  : 'Koneksi Terputus Terpaksa',
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isStillConnected
                                  ? 'Sukses tersambung dengan alamat IP: $alamatIP'
                                  : 'Pipa jaringan ke alamat server $alamatIP tiba-tiba terputus di tengah jalan.',
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isStillConnected
                                    ? Colors.teal.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isStillConnected
                                      ? Colors.teal.shade200
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                isStillConnected
                                    ? 'Anda bisa memantau proses penerimaan otomatis, atau mengirim balik data lokal HP ini ke Server.'
                                    : 'Hubungan terputus akibat server mati atau jaringan terganggu. Tombol transfer dinonaktifkan.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: isStillConnected
                                      ? Colors.black87
                                      : Colors.red[900],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isStillConnected
                                    ? () => fungsiKirimDataClient()
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  disabledBackgroundColor: Colors.grey[200],
                                ),
                                icon: const Icon(
                                  Icons.upload_file,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Kirim Data Saya Ke Server',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              channel.sink.close();
                              Navigator.pop(ctx);
                            },
                            child: Text(
                              isStillConnected
                                  ? 'Putuskan Koneksi'
                                  : 'Tutup Dialog',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ).then((_) {
                  isDialogOpened = false;
                  clientDialogState = null;
                });
              }
            },
            onDone: () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                isStillConnected = false;
                if (clientDialogState != null) clientDialogState!(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Hubungan ke Server terputus secara tiba-tiba!',
                    ),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
            onError: (err) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                isStillConnected = false;
                if (clientDialogState != null) clientDialogState!(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gagal terhubung! Jaringan ditolak perangkat $alamatIP.',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan fatal jaringan.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // --- LOGIKA DIALOG KONFIRMASI HAPUS ---
  Future<bool> _showConfirmDeleteDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kirim & Terima Data Lokal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gunakan fitur ini untuk mentransfer seluruh isi folder utama (RSpace_data & PerpusKu) secara wireless antar perangkat yang terhubung dalam satu jaringan Wi-Fi yang sama.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _startServerSharing(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.wifi_tethering,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Aktifkan Server',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showConnectToServerDialog(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.add_to_home_screen,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Hubungkan ke Server',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Berkas Diterima dari Server',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                FittedBox(
                  child: Row(
                    children: [
                      if (_isServerSelectionMode) ...[
                        IconButton(
                          icon: Icon(
                            _selectedServerFiles.length ==
                                    _serverBackupFiles.length
                                ? Icons.deselect
                                : Icons.select_all,
                            size: 18,
                            color: Colors.teal[700],
                          ),
                          tooltip:
                              _selectedServerFiles.length ==
                                  _serverBackupFiles.length
                              ? 'Batal Semua'
                              : 'Pilih Semua',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          onPressed: () {
                            setState(() {
                              if (_selectedServerFiles.length ==
                                  _serverBackupFiles.length) {
                                _selectedServerFiles.clear();
                              } else {
                                _selectedServerFiles.clear();
                                _selectedServerFiles.addAll(_serverBackupFiles);
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_selectedServerFiles.length} Terpilih',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _selectedServerFiles.isEmpty
                              ? null
                              : () async {
                                  final bool
                                  confirm = await _showConfirmDeleteDialog(
                                    title: 'Hapus Masal Berkas Server',
                                    content:
                                        'Apakah Anda yakin ingin menghapus ${_selectedServerFiles.length} berkas yang diterima dari server terpilih secara permanen?',
                                  );
                                  if (confirm) {
                                    for (var file in _selectedServerFiles) {
                                      if (await file.exists()) {
                                        await file.delete();
                                      }
                                    }
                                    setState(() {
                                      _selectedServerFiles.clear();
                                      _isServerSelectionMode = false;
                                    });
                                    _loadServerBackups();
                                  }
                                },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedServerFiles.isEmpty
                                  ? Colors.grey[200]
                                  : Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _selectedServerFiles.isEmpty
                                    ? Colors.grey[300]!
                                    : Colors.red.withOpacity(0.2),
                              ),
                            ),
                            child: Icon(
                              Icons.delete_sweep,
                              size: 18,
                              color: _selectedServerFiles.isEmpty
                                  ? Colors.grey[400]
                                  : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedServerFiles.clear();
                              _isServerSelectionMode = false;
                            });
                          },
                          child: const Text(
                            'Batal',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _serverBackupFiles.isEmpty
                ? const SizedBox(
                    height: 150,
                    child: Center(
                      child: Text(
                        'Belum ada berkas data yang diterima dari server sharing.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _serverBackupFiles.length,
                    itemBuilder: (context, index) {
                      final file = _serverBackupFiles[index];
                      final isSelected = _selectedServerFiles.contains(file);
                      final String fileName = file.path.split('/').last;
                      return ListTile(
                        onLongPress: () {
                          setState(() {
                            _isServerSelectionMode = true;
                            if (!isSelected) _selectedServerFiles.add(file);
                          });
                        },
                        onTap: _isServerSelectionMode
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedServerFiles.remove(file);
                                  } else {
                                    _selectedServerFiles.add(file);
                                  }
                                });
                              }
                            : () async {
                                final bool confirm =
                                    await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.orange[800],
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Restore Paket Server?'),
                                          ],
                                        ),
                                        content: Text(
                                          'Apakah Anda yakin ingin melakukan sinkronisasi pemulihan total menggunakan berkas jaringan "$fileName"?\n\n*Peringatan: Seluruh data aktif folder RSpace_data and PerpusKu saat ini akan dihapus bersih lalu ditimpa.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text(
                                              'Batal',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.indigo,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'Ya, Restore All',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (confirm) {
                                  _importAllFromZip(file);
                                }
                              },
                        leading: _isServerSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                activeColor: Colors.red,
                                onChanged: (bool? checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedServerFiles.add(file);
                                    } else {
                                      _selectedServerFiles.remove(file);
                                    }
                                  });
                                },
                              )
                            : const Icon(
                                Icons.cloud_download,
                                color: Colors.teal,
                              ),
                        title: Text(fileName),
                        trailing: _isServerSelectionMode
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final bool
                                  confirm = await _showConfirmDeleteDialog(
                                    title: 'Hapus Berkas Server',
                                    content:
                                        'Apakah Anda yakin ingin menghapus berkas "$fileName" ini secara permanen?',
                                  );
                                  if (confirm && await file.exists()) {
                                    await file.delete();
                                    _loadServerBackups();
                                  }
                                },
                              ),
                      );
                    },
                  ),
          ],
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: Card(
                elevation: 4,
                shape: CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
