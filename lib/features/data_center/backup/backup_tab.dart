// lib/features/data_center/presentation/widgets/backup_tab.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_aplication/features/data_center/presentation/widgets/last_restore_banner.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:my_aplication/features/content_management/topics/providers/topic_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/path_service.dart';

class BackupTab extends StatefulWidget {
  const BackupTab({super.key});

  @override
  State<BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends State<BackupTab> {
  final StorageService _storageService = StorageService();
  final PathService _pathService = PathService();

  String _baseDir = 'Documents';
  List<File> _localBackupFiles = [];
  bool _isLoading = false;
  bool _isSelectionMode = false;
  final List<File> _selectedFiles = [];

  // Variabel untuk menyimpan status restore terakhir
  Map<String, String>? _lastRestoreInfo;

  @override
  void initState() {
    super.initState();
    _loadBaseDirectory();
    _loadLastRestoreStatus(); // Memuat status riwayat restore saat inisialisasi
  }

  // Memuat data restore terakhir dari storage service
  Future<void> _loadLastRestoreStatus() async {
    final info = await _storageService.getLastRestoreInfo();
    if (mounted) {
      setState(() {
        _lastRestoreInfo = info;
      });
    }
  }

  // --- LOGIKA MANAJEMEN DIREKTORI & BERKAS LOKAL ---
  Future<void> _loadBaseDirectory() async {
    String dir = await _storageService.getBaseDirSetting();
    if (mounted) {
      setState(() {
        _baseDir = dir;
      });
      _loadLocalBackups();
    }
  }

  Future<void> _loadLocalBackups() async {
    List<File> files = await _storageService.getAllLocalBackupFiles(_baseDir);
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    setState(() {
      _localBackupFiles = files;
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

  // --- LOGIKA UTAMA: PENCADANGAN GLOBAL (ZIP) VIA STORAGE SERVICE ---
  void _backupAllFeature() async {
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

      String namaZipDinamis = _getFormattedFileName('local_backup', 'zip');

      await _storageService.createBackupZip(
        mainFolderPath: mainFolderPath,
        baseDir: _baseDir,
        fileName: namaZipDinamis,
        isServerSharing: false,
      );

      _loadLocalBackups();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup seluruh folder utama berhasil disimpan: $namaZipDinamis',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      debugPrint("Gagal membuat backup folder utama ke ZIP: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat backup: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA UTAMA: PEMULIHAN GLOBAL (RESTORE ZIP) ---
  void _importAllFromZip(File zipFile, {required String sourceName}) async {
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
      final String destinationPath = rootDir.path;

      // 1. PENERAPAN PENGHAPUSAN BERSIH SEBELUM RESTORE
      final Directory activeRSpaceDir = Directory(
        path.join(destinationPath, 'RSpace_data'),
      );
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
        String fullPathTarget = path.join(destinationPath, file.name);
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

      // 🌟 MENYIMPAN INFORMASI RESTORE TERAKHIR KETIKA BERHASIL
      final String fileNameOnly = zipFile.path.split('/').last;
      await _storageService.saveLastRestoreInfo(
        fileName: fileNameOnly,
        source: sourceName,
      );
      await _loadLastRestoreStatus(); // Refresh tampilan info banner

      if (mounted) {
        Provider.of<TopicProvider>(context, listen: false).fetchTopics();
      }

      setState(() {
        _loadBaseDirectory();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore Berhasil! Seluruh folder disinkronkan dari "$fileNameOnly".',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      debugPrint("Gagal mengimpor file ZIP global ke folder utama: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal melakukan restore: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _exportBackupToCustomFolder(File fileBackup) async {
    try {
      final String namaFile = fileBackup.path.split('/').last;

      if (Platform.isLinux) {
        String? lokasiSimpan = await FilePicker.saveFile(
          dialogTitle: 'Simpan Berkas Cadangan',
          fileName: namaFile,
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );
        if (lokasiSimpan != null) {
          await fileBackup.copy(lokasiSimpan);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berkas berhasil disimpan ke: $lokasiSimpan'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        setState(() => _isLoading = true);

        final result = await Share.shareXFiles(
          [XFile(fileBackup.path)],
          text: 'Ekspor Berkas Cadangan Aplikasi',
          subject: namaFile,
        );

        setState(() => _isLoading = false);

        if (!mounted) return;

        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berkas cadangan berhasil diekspor!'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Gagal mengekspor berkas backup ke folder kustom: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekspor berkas: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _importZipLokal() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result != null && result.files.single.path != null) {
        File selectedZipFile = File(result.files.single.path!);
        if (!mounted) return;
        final bool confirm =
            await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Import & Restore ZIP?'),
                  ],
                ),
                content: Text(
                  'Apakah Anda yakin ingin memulihkan data dari berkas luar "${selectedZipFile.path.split('/').last}"?\n\n*Peringatan: Seluruh data aktif aplikasi (RSpace & Perpusku) saat ini akan dihapus dan ditimpa secara permanen.',
                ),
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
        if (confirm) {
          _importAllFromZip(
            selectedZipFile,
            sourceName: 'ZIP Luar (File Picker)',
          );
        }
      }
    } catch (e) {
      debugPrint("Gagal mengimport file cadangan ZIP: $e");
    }
  }

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
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Konfirmasi Hapus'),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // 🌟 PANGGIL WIDGET BANNER BERSAMA DI SINI (PALING ATAS SCREEN)
            LastRestoreBanner(lastRestoreInfo: _lastRestoreInfo),

            // === Informasi Modul Utama ===
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_copy_rounded,
                      color: Colors.indigo[700],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pencadangan Folder Utama',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Mengompresi folder RSpace_data dan PerpusKu secara utuh ke dalam satu file ZIP.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(thickness: 1),

            // === Bagian Header Daftar Berkas & Tombol Kontrol Dinamis ===
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Berkas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  FittedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_isSelectionMode) ...[
                          IconButton(
                            icon: Icon(
                              _selectedFiles.length == _localBackupFiles.length
                                  ? Icons.deselect
                                  : Icons.select_all,
                              size: 18,
                              color: Colors.teal[700],
                            ),
                            tooltip:
                                _selectedFiles.length ==
                                    _localBackupFiles.length
                                ? 'Batal Semua'
                                : 'Pilih Semua',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                            onPressed: () {
                              setState(() {
                                if (_selectedFiles.length ==
                                    _localBackupFiles.length) {
                                  _selectedFiles.clear();
                                } else {
                                  _selectedFiles.clear();
                                  _selectedFiles.addAll(_localBackupFiles);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_selectedFiles.length} Terpilih',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _selectedFiles.isEmpty
                                ? null
                                : () async {
                                    final bool
                                    confirm = await _showConfirmDeleteDialog(
                                      title: 'Hapus Masal',
                                      content:
                                          'Apakah Anda yakin ingin menghapus ${_selectedFiles.length} berkas cadangan terpilih secara permanen?',
                                    );
                                    if (confirm) {
                                      for (var file in _selectedFiles) {
                                        if (await file.exists()) {
                                          await file.delete();
                                        }
                                      }
                                      setState(() {
                                        _selectedFiles.clear();
                                        _isSelectionMode = false;
                                      });
                                      _loadLocalBackups();
                                    }
                                  },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedFiles.isEmpty
                                    ? Colors.grey[200]
                                    : Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _selectedFiles.isEmpty
                                      ? Colors.grey[300]!
                                      : Colors.red.withOpacity(0.2),
                                ),
                              ),
                              child: Icon(
                                Icons.delete_sweep,
                                size: 18,
                                color: _selectedFiles.isEmpty
                                    ? Colors.grey[400]
                                    : Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
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
                                _selectedFiles.clear();
                                _isSelectionMode = false;
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
                        ] else ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _importZipLokal(),
                                icon: const Icon(
                                  Icons.unarchive,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Import ZIP',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _backupAllFeature(),
                                icon: const Icon(
                                  Icons.folder_zip_outlined,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Buat Backup',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // === Daftar File ZIP Lokal ===
            _localBackupFiles.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 32.0),
                      child: Text('Belum ada file backup.'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _localBackupFiles.length,
                    itemBuilder: (context, index) {
                      final file = _localBackupFiles[index];
                      final isSelected = _selectedFiles.contains(file);
                      final String fileName = file.path.split('/').last;
                      return ListTile(
                        onLongPress: () {
                          setState(() {
                            _isSelectionMode = true;
                            if (!isSelected) _selectedFiles.add(file);
                          });
                        },
                        onTap: _isSelectionMode
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedFiles.remove(file);
                                  } else {
                                    _selectedFiles.add(file);
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
                                            const Text(
                                              'Restore Data Aplikasi?',
                                            ),
                                          ],
                                        ),
                                        content: Text(
                                          'Apakah Anda yakin ingin memulihkan seluruh data menggunakan file cadangan "$fileName"?\n\n*Peringatan: Folder RSpace_data dan PerpusKu aktif saat ini akan sepenuhnya ditimpa.',
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
                                              'Ya, Restore',
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
                                  // Mengirimkan parameter nama sumber 'Backup Lokal' saat restore
                                  _importAllFromZip(
                                    file,
                                    sourceName: 'Backup Lokal',
                                  );
                                }
                              },
                        leading: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                activeColor: Colors.red,
                                onChanged: (bool? checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedFiles.add(file);
                                    } else {
                                      _selectedFiles.remove(file);
                                    }
                                  });
                                },
                              )
                            : const Icon(Icons.folder_zip, color: Colors.amber),
                        title: Text(fileName),
                        trailing: _isSelectionMode
                            ? null
                            : PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.grey,
                                ),
                                padding: EdgeInsets.zero,
                                onSelected: (value) async {
                                  if (value == 'export_folder') {
                                    _exportBackupToCustomFolder(file);
                                  } else if (value == 'delete_backup') {
                                    final bool
                                    confirm = await _showConfirmDeleteDialog(
                                      title: 'Hapus Berkas Backup',
                                      content:
                                          'Apakah Anda yakin ingin menghapus berkas cadangan "$fileName" secara permanen?',
                                    );
                                    if (confirm && await file.exists()) {
                                      await file.delete();
                                      _loadLocalBackups();
                                    }
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem<String>(
                                    value: 'export_folder',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.drive_file_move,
                                        color: Colors.indigo,
                                        size: 20,
                                      ),
                                      title: Text('Simpan'),
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem<String>(
                                    value: 'delete_backup',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      title: Text(
                                        'Hapus Permanen',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ),
                                  ),
                                ],
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
