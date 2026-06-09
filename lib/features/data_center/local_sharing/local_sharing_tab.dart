// lib/features/data_center/presentation/widgets/local_sharing_tab.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

import 'package:my_aplication/features/content_management/topics/providers/topic_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/path_service.dart';

// Import Handler yang sudah dipisah
import 'server_sharing_handler.dart';
import 'client_sharing_handler.dart';

class LocalSharingTab extends StatefulWidget {
  const LocalSharingTab({super.key});

  @override
  State<LocalSharingTab> createState() => _LocalSharingTabState();
}

class _LocalSharingTabState extends State<LocalSharingTab> {
  final StorageService _storageService = StorageService();
  final PathService _pathService = PathService();

  late final ServerSharingHandler _serverHandler;
  late final ClientSharingHandler _clientHandler;

  String _baseDir = 'Documents';
  List<File> _serverBackupFiles = [];
  bool _isLoading = false;
  bool _isServerSelectionMode = false;
  final List<File> _selectedServerFiles = [];

  @override
  void initState() {
    super.initState();
    // Inisialisasi Handler
    _serverHandler = ServerSharingHandler(
      storageService: _storageService,
      pathService: _pathService,
    );
    _clientHandler = ClientSharingHandler(
      storageService: _storageService,
      pathService: _pathService,
    );
    _loadBaseDirectory();
  }

  @override
  void dispose() {
    // Pastikan server ditutup saat keluar dari tab
    _serverHandler.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

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

  // --- LOGIKA UTAMA: RESTORE DATA DARI ZIP ---
  void _importAllFromZip(File zipFile) async {
    _setLoading(true);
    try {
      final String appBasePath =
          await _pathService.loadCustomStoragePath() ?? "";

      // Ambil root direktori sesuai perubahan baru (tanpa RSpace_App)
      Directory rootDir = appBasePath.isNotEmpty
          ? Directory(appBasePath)
          : Directory(await _pathService.profilePicturesPath).parent;

      final String destinationPath = rootDir.path;

      // PERBAIKAN: Target RSpace_data & PerpusKu langsung berada di pusat root destinationPath
      Directory activeRSpaceDir = Directory(
        path.join(destinationPath, 'RSpace_data'),
      );
      final Directory activePerpuskuDir = Directory(
        path.join(destinationPath, 'PerpusKu'),
      );

      // Hapus data aktif lama di folder pusat jika ada sebelum menimpa
      if (activeRSpaceDir.existsSync()) {
        await activeRSpaceDir.delete(recursive: true);
      }
      if (activePerpuskuDir.existsSync()) {
        await activePerpuskuDir.delete(recursive: true);
      }

      List<int> bytes = await zipFile.readAsBytes();
      Archive archive = ZipDecoder().decodeBytes(bytes);

      for (ArchiveFile file in archive) {
        // PERBAIKAN UTAMA: Hilangkan kondisi pencabangan 'data' lama.
        // Seluruh isi zip langsung diekstrak relatif terhadap destinationPath pusat.
        String targetFolder = destinationPath;
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
      _loadServerBackups();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore Berhasil dari "${zipFile.path.split('/').last}".',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal melakukan restore: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      _setLoading(false);
    }
  }

  // --- DIALOG KONFIRMASI RESTORE (PERBAIKAN) ---
  Future<bool> _showConfirmRestoreDialog({
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
                Icon(Icons.warning_amber_rounded, color: Colors.orange[800]),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Ya, Restore',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // --- DIALOG KONFIRMASI HAPUS ---
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
                child: const Text('Batal'),
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
            // === Card Koneksi Jaringan ===
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
                      'Transfer seluruh isi folder utama secara wireless antar perangkat dalam satu jaringan Wi-Fi.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _serverHandler.startServerSharing(
                              context: context,
                              baseDir: _baseDir,
                              setLoading: _setLoading,
                              onRefresh: _loadServerBackups,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.wifi_tethering),
                            label: const Text('Aktifkan Server'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _clientHandler.showConnectDialog(
                              context: context,
                              baseDir: _baseDir,
                              setLoading: _setLoading,
                              onRefresh: _loadServerBackups,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add_to_home_screen),
                            label: const Text('Hubungkan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === Bagian Header Daftar Berkas & Tombol Kontrol Dinamis ===
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Berkas Diterima dari Server',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  FittedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_isServerSelectionMode) ...[
                          // Tombol Pilih / Batal Pilih Semua
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
                                  _selectedServerFiles.addAll(
                                    _serverBackupFiles,
                                  );
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
                          // Tombol Hapus Masal
                          InkWell(
                            onTap: _selectedServerFiles.isEmpty
                                ? null
                                : () async {
                                    final bool
                                    confirm = await _showConfirmDeleteDialog(
                                      title: 'Hapus Masal Berkas',
                                      content:
                                          'Apakah Anda yakin ingin menghapus ${_selectedServerFiles.length} berkas cadangan terpilih secara permanen?',
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
                          // Tombol Batalkan Seluruh Mode Pilihan
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
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
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // === Daftar Berkas Backup ZIP ===
            _serverBackupFiles.isEmpty
                ? const SizedBox(
                    height: 150,
                    child: Center(
                      child: Text(
                        'Belum ada berkas data yang diterima.',
                        style: TextStyle(color: Colors.grey),
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
                        onLongPress: () => setState(() {
                          _isServerSelectionMode = true;
                          if (!isSelected) _selectedServerFiles.add(file);
                        }),
                        onTap: _isServerSelectionMode
                            ? () => setState(() {
                                isSelected
                                    ? _selectedServerFiles.remove(file)
                                    : _selectedServerFiles.add(file);
                              })
                            : () async {
                                // PERBAIKAN: Memanggil _showConfirmRestoreDialog yang baru
                                final confirm = await _showConfirmRestoreDialog(
                                  title: 'Restore Data Aplikasi?',
                                  content:
                                      'Apakah Anda yakin ingin memulihkan seluruh data menggunakan file cadangan "$fileName"?\n\n*Peringatan: Folder RSpace_data dan PerpusKu aktif saat ini akan sepenuhnya ditimpa.',
                                );
                                if (confirm) _importAllFromZip(file);
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
                                  final confirm = await _showConfirmDeleteDialog(
                                    title: 'Hapus Berkas Backup',
                                    content:
                                        'Apakah Anda yakin ingin menghapus berkas cadangan "$fileName" secara permanen?',
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
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              ),
            ),
          ),
      ],
    );
  }
}
