// lib/features/file_management/presentation/pages/file_list_page.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/features/backup_management/presentation/utils/backup_actions.dart';
import 'package:my_aplication/features/backup_management/presentation/utils/file_utils.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../auth/presentation/profile_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../application/file_provider.dart';
import '../../domain/models/file_model.dart';

class FileListPage extends StatelessWidget {
  const FileListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FileProvider()),
        ChangeNotifierProvider.value(value: Provider.of<AuthProvider>(context)),
      ],
      child: const _FileListPageView(),
    );
  }
}

class _FileListPageView extends StatefulWidget {
  const _FileListPageView();

  @override
  State<_FileListPageView> createState() => _FileListPageViewState();
}

class _FileListPageViewState extends State<_FileListPageView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        // Rebuild untuk memperbarui AppBar saat tab berubah
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Consumer<FileProvider>(
      builder: (context, provider, child) {
        if (auth.authState != AuthState.authenticated) {
          return _buildLoginRequiredView(context);
        }

        final bool showSelectionAppBar =
            provider.isSelectionMode && _tabController.index == 1;

        return Scaffold(
          appBar: showSelectionAppBar
              ? _buildSelectionAppBar(context, provider)
              : _buildDefaultAppBar(context, provider),
          body: WillPopScope(
            onWillPop: () async {
              if (provider.isSelectionMode) {
                provider.clearSelection();
                return false;
              }
              return true;
            },
            child: Builder(
              builder: (context) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return _buildErrorView(context, provider);
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Online Files
                    RefreshIndicator(
                      onRefresh: () => provider.fetchFiles(),
                      child: _OnlineFilesTab(parent: this),
                    ),
                    // Tab 2: Downloaded Files
                    RefreshIndicator(
                      onRefresh: () => provider.fetchFiles(),
                      child: _DownloadedFilesTab(parent: this),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ============== WIDGETS & DIALOGS ==============

  Widget _buildLoginRequiredView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Online')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Login Diperlukan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Anda harus login untuk mengakses file online dan fitur sinkronisasi.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Login atau Buat Akun'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildDefaultAppBar(BuildContext context, FileProvider provider) {
    final bool isApiConfigured =
        provider.apiDomain != null && provider.apiDomain!.isNotEmpty;
    final bool isSyncInProgress = !provider.syncProgress.isFinished;

    return AppBar(
      title: const Text('File Online & Unduhan'),
      actions: [
        if (isApiConfigured)
          IconButton(
            icon: isSyncInProgress
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download_for_offline_outlined),
            onPressed: isSyncInProgress
                ? null
                : () => provider.downloadAndImportAll(context),
            tooltip: 'Download & Import Semua',
          ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.cloud_outlined), text: 'Online'),
          Tab(icon: Icon(Icons.folder_outlined), text: 'Unduhan'),
        ],
      ),
    );
  }

  AppBar _buildSelectionAppBar(BuildContext context, FileProvider provider) {
    return AppBar(
      title: Text('${provider.selectedDownloadedFiles.length} dipilih'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => provider.clearSelection(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: () => provider.selectAllDownloaded(),
          tooltip: 'Pilih Semua',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            final confirmed = await _showConfirmationDialog(
              context,
              'Konfirmasi Hapus',
              'Anda yakin ingin menghapus ${provider.selectedDownloadedFiles.length} file ini dari perangkat?',
            );
            if (confirmed) {
              final message = await provider.deleteSelectedDownloadedFiles();
              if (context.mounted) {
                showAppSnackBar(context, message);
              }
            }
          },
          tooltip: 'Hapus Pilihan',
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, FileProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Error: ${provider.errorMessage}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: provider.isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.refresh),
              label: Text(provider.isLoading ? 'Memuat...' : 'Coba Lagi'),
              onPressed: provider.isLoading
                  ? null
                  : () => provider.fetchFiles(),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Buka Pengaturan Server'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ).then((_) => provider.fetchFiles());
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============== LOGIKA & HELPER METHODS ==============

  Future<void> _uploadFile(BuildContext context, bool isRspaceFile) async {
    final provider = Provider.of<FileProvider>(context, listen: false);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        final file = result.files.first;
        if (context.mounted) {
          showAppSnackBar(context, 'Mengunggah ${file.name}...');
        }
        final message = await provider.uploadFile(file, isRspaceFile);
        if (context.mounted) {
          showAppSnackBar(context, message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Gagal mengunggah: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteFile(
    BuildContext context,
    FileItem file,
    bool isRspaceFile,
  ) async {
    final provider = Provider.of<FileProvider>(context, listen: false);
    try {
      final confirmed = await _showConfirmationDialog(
        context,
        'Konfirmasi Hapus',
        'Anda yakin ingin menghapus file "${file.originalName}" dari server?',
      );
      if (confirmed) {
        final message = await provider.deleteFile(file, isRspaceFile);
        if (context.mounted) {
          showAppSnackBar(context, message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Gagal menghapus: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteDownloadedFile(BuildContext context, File file) async {
    final provider = Provider.of<FileProvider>(context, listen: false);
    try {
      final confirmed = await _showConfirmationDialog(
        context,
        'Konfirmasi Hapus Lokal',
        'Anda yakin ingin menghapus file "${path.basename(file.path)}" dari perangkat Anda?',
      );
      if (confirmed) {
        final message = await provider.deleteDownloadedFile(file);
        if (context.mounted) {
          showAppSnackBar(context, message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Gagal menghapus file lokal: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildFileSection(
    BuildContext context, {
    required FileProvider provider,
    required String title,
    required List<FileItem> files,
    required bool isRspaceFile,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Unggah'),
              onPressed: provider.isUploading
                  ? null
                  : () => _uploadFile(context, isRspaceFile),
            ),
          ],
        ),
        const Divider(),
        if (files.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: Text('Tidak ada file online ditemukan.')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return _buildFileListItem(context, file, isRspaceFile);
            },
          ),
      ],
    );
  }

  Widget _buildDownloadedFileSection(
    BuildContext context, {
    required FileProvider provider,
    required String title,
    required List<File> files,
    required bool isRspaceFile,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        if (files.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: Text('Tidak ada file yang telah diunduh.')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return _buildDownloadedFileListItem(context, file, isRspaceFile);
            },
          ),
      ],
    );
  }

  Widget _buildFileListItem(
    BuildContext context,
    FileItem file,
    bool isRspaceFile,
  ) {
    final provider = Provider.of<FileProvider>(context);
    final progress = provider.getDownloadProgress(file.uniqueName);
    final isDownloading = progress > 0;
    final uploadedDate = DateTime.tryParse(file.uploadedAt);
    final formattedDate = uploadedDate != null
        ? DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(uploadedDate)
        : file.uploadedAt;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: const Icon(Icons.cloud_queue_rounded),
        title: Text(file.originalName),
        subtitle: Text('Diunggah: $formattedDate'),
        trailing: isDownloading
            ? CircularProgressIndicator(
                value: progress > 0.01 ? progress : null,
              )
            : PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'download') {
                    try {
                      await provider.downloadFile(file, isRspaceFile);
                      if (context.mounted) {
                        showAppSnackBar(
                          context,
                          'Mengunduh ${file.originalName}...',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showAppSnackBar(
                          context,
                          'Gagal mengunduh: $e',
                          isError: true,
                        );
                      }
                    }
                  } else if (value == 'delete') {
                    _deleteFile(context, file, isRspaceFile);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'download',
                    child: Text('Download'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDownloadedFileListItem(
    BuildContext context,
    File file,
    bool isRspaceFile,
  ) {
    final provider = Provider.of<FileProvider>(context);
    final isSelected = provider.selectedDownloadedFiles.contains(file.path);
    final theme = Theme.of(context);
    final fileName = path.basename(file.path);
    final fileSize = file.lengthSync();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: isSelected ? theme.primaryColor.withOpacity(0.2) : null,
      child: ListTile(
        onTap: () {
          if (provider.isSelectionMode) {
            provider.toggleDownloadedFileSelection(file);
          } else {
            OpenFile.open(file.path);
          }
        },
        onLongPress: () {
          provider.toggleDownloadedFileSelection(file);
        },
        leading: isSelected
            ? Icon(Icons.check_circle, color: theme.primaryColor)
            : const Icon(Icons.drafts_rounded),
        title: Text(fileName),
        subtitle: Text('Ukuran: ${formatBytes(fileSize, 2)}'),
        trailing: provider.isSelectionMode
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'open') {
                    await OpenFile.open(file.path);
                  } else if (value == 'import') {
                    final backupType = isRspaceFile ? 'RSpace' : 'PerpusKu';
                    importSpecificFile(
                      context,
                      file,
                      backupType,
                      showConfirmation: true,
                    );
                  } else if (value == 'delete') {
                    _deleteDownloadedFile(context, file);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'open', child: Text('Buka File')),
                  const PopupMenuItem(value: 'import', child: Text('Import')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
      ),
    );
  }
}

// Widget untuk Tab Online
class _OnlineFilesTab extends StatelessWidget {
  final _FileListPageViewState parent;
  const _OnlineFilesTab({required this.parent});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FileProvider>(context);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        parent._buildFileSection(
          context,
          provider: provider,
          title: 'RSpace',
          files: provider.rspaceFiles,
          isRspaceFile: true,
        ),
        const SizedBox(height: 24),
        parent._buildFileSection(
          context,
          provider: provider,
          title: 'PerpusKu',
          files: provider.perpuskuFiles,
          isRspaceFile: false,
        ),
      ],
    );
  }
}

// Widget untuk Tab Unduhan
class _DownloadedFilesTab extends StatelessWidget {
  final _FileListPageViewState parent;
  const _DownloadedFilesTab({required this.parent});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FileProvider>(context);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        parent._buildDownloadedFileSection(
          context,
          provider: provider,
          title: 'RSpace',
          files: provider.downloadedRspaceFiles,
          isRspaceFile: true,
        ),
        const SizedBox(height: 24),
        parent._buildDownloadedFileSection(
          context,
          provider: provider,
          title: 'PerpusKu',
          files: provider.downloadedPerpuskuFiles,
          isRspaceFile: false,
        ),
      ],
    );
  }
}
