// lib/presentation/pages/file_list_page.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_aplication/presentation/pages/backup_management_page/utils/backup_actions.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../providers/file_provider.dart';
import '../../data/models/file_model.dart';
import '../pages/1_topics_page/utils/scaffold_messenger_utils.dart';
import 'backup_management_page/utils/file_utils.dart';

class FileListPage extends StatelessWidget {
  const FileListPage({super.key});

  Future<void> _selectDownloadFolder(BuildContext context) async {
    final provider = Provider.of<FileProvider>(context, listen: false);
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Tujuan Download',
    );

    if (selectedDirectory != null) {
      await provider.setDownloadPath(selectedDirectory);
      if (context.mounted) {
        showAppSnackBar(context, 'Folder tujuan download berhasil diatur.');
      }
    } else {
      if (context.mounted) {
        showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
      }
    }
  }

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
      } else {
        if (context.mounted) {
          showAppSnackBar(context, 'Pemilihan file dibatalkan.');
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
        if (context.mounted) {
          showAppSnackBar(context, 'Menghapus ${file.originalName}...');
        }
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
        if (context.mounted) {
          showAppSnackBar(
            context,
            'Menghapus ${path.basename(file.path)} dari perangkat...',
          );
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar File Online & Unduhan')),
      body: ChangeNotifierProvider(
        create: (_) => FileProvider(),
        child: Consumer<FileProvider>(
          builder: (context, provider, child) {
            // Tampilkan loading indicator hanya jika isLoading true
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Tampilkan pesan error jika ada
            if (provider.errorMessage != null &&
                provider.rspaceFiles.isEmpty &&
                provider.perpuskuFiles.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${provider.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Hanya tampilkan tombol "Coba Lagi" jika bukan error konfigurasi
                      if (!provider.errorMessage!.contains('Konfigurasi'))
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          onPressed: () => provider.fetchFiles(),
                        ),
                      const SizedBox(height: 24),
                      // Selalu tampilkan kartu konfigurasi jika ada error
                      _ApiConfigCard(),
                    ],
                  ),
                ),
              );
            }

            // Tampilan utama jika tidak ada loading atau error
            return RefreshIndicator(
              onRefresh: () =>
                  Future.wait([provider.fetchFiles(), provider.fetchFiles()]),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _ApiConfigCard(),
                  const SizedBox(height: 16),
                  _buildPathInfoCard(context),
                  const SizedBox(height: 24),
                  _buildFileSection(
                    context,
                    provider: provider,
                    title: 'File Online RSpace',
                    files: provider.rspaceFiles,
                    isRspaceFile: true,
                  ),
                  const SizedBox(height: 24),
                  _buildFileSection(
                    context,
                    provider: provider,
                    title: 'File Online Perpusku',
                    files: provider.perpuskuFiles,
                    isRspaceFile: false,
                  ),
                  const SizedBox(height: 24),
                  _buildDownloadedFileSection(
                    context,
                    provider: provider,
                    title: 'Unduhan RSpace',
                    files: provider.downloadedRspaceFiles,
                    isRspaceFile: true,
                  ),
                  const SizedBox(height: 24),
                  _buildDownloadedFileSection(
                    context,
                    provider: provider,
                    title: 'Unduhan Perpusku',
                    files: provider.downloadedPerpuskuFiles,
                    isRspaceFile: false,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPathInfoCard(BuildContext context) {
    // ... (sisa kode sama seperti sebelumnya) ...
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Folder Tujuan Download',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<FileProvider>(
              builder: (context, provider, child) {
                final theme = Theme.of(context);
                final String displayText =
                    provider.downloadPath ?? 'Folder belum ditentukan.';
                final TextStyle? textStyle = theme.textTheme.bodyMedium
                    ?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: kDebugMode && provider.downloadPath != null
                          ? FontWeight.bold
                          : null,
                    );

                return Text(displayText, style: textStyle);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Ubah Folder Tujuan'),
                onPressed: () => _selectDownloadFolder(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSection(
    BuildContext context, {
    required FileProvider provider,
    required String title,
    required List<FileItem> files,
    required bool isRspaceFile,
  }) {
    // ... (sisa kode sama seperti sebelumnya) ...
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Unggah'),
              onPressed: provider.isUploading
                  ? null
                  : () => _uploadFile(context, isRspaceFile),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const Divider(thickness: 2),
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
              final progress = provider.getDownloadProgress(file.uniqueName);
              final isDownloading = progress > 0;
              final uploadProgress = provider.getUploadProgress(
                file.originalName,
              );
              final isUploading = uploadProgress > 0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: const Icon(Icons.cloud_queue_rounded),
                  title: Text(file.originalName),
                  subtitle: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall,
                      children: [
                        const TextSpan(text: 'Diunggah: '),
                        TextSpan(
                          text: file.uploadedAt,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: isDownloading
                      ? CircularProgressIndicator(
                          value: progress > 0.01 ? progress : null,
                        )
                      : isUploading
                      ? CircularProgressIndicator(
                          value: uploadProgress > 0.01 ? uploadProgress : null,
                        )
                      : PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'download') {
                              try {
                                final message = await provider.downloadFile(
                                  file,
                                  isRspaceFile,
                                );
                                if (context.mounted) {
                                  showAppSnackBar(context, message);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  showAppSnackBar(
                                    context,
                                    'Gagal mengunduh: ${e.toString()}',
                                    isError: true,
                                  );
                                }
                              }
                            } else if (value == 'delete') {
                              _deleteFile(context, file, isRspaceFile);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'download',
                                  child: Text('Download'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                        ),
                ),
              );
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
    // ... (sisa kode sama seperti sebelumnya) ...
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(thickness: 2),
        if (provider.downloadPath == null || provider.downloadPath!.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'Folder tujuan download belum ditentukan.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (files.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'Tidak ada file yang telah diunduh di sini.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final fileName = path.basename(file.path);
              final fileSize = file.lengthSync();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: const Icon(Icons.drafts_rounded),
                  title: Text(fileName),
                  subtitle: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall,
                      children: [
                        const TextSpan(text: 'Ukuran: '),
                        TextSpan(
                          text: formatBytes(fileSize, 2),
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'open') {
                        final result = await OpenFile.open(file.path);
                        if (result.type != ResultType.done && context.mounted) {
                          showAppSnackBar(
                            context,
                            'Tidak dapat membuka file: ${result.message}',
                            isError: true,
                          );
                        }
                      } else if (value == 'import') {
                        final backupType = isRspaceFile ? 'RSpace' : 'PerpusKu';
                        importSpecificFile(context, file, backupType);
                      } else if (value == 'delete') {
                        _deleteDownloadedFile(context, file);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'open',
                            child: Text('Buka File'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'import',
                            child: Text('Import'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(
                              'Hapus',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ApiConfigCard extends StatefulWidget {
  @override
  State<_ApiConfigCard> createState() => _ApiConfigCardState();
}

class _ApiConfigCardState extends State<_ApiConfigCard> {
  late TextEditingController _domainController;
  late TextEditingController _apiKeyController;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<FileProvider>(context, listen: false);
    // Inisialisasi controller dengan nilai dari provider atau string kosong
    _domainController = TextEditingController(text: provider.apiDomain ?? '');
    _apiKeyController = TextEditingController(text: provider.apiKey ?? '');
  }

  @override
  void dispose() {
    _domainController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _saveConfig() {
    final provider = Provider.of<FileProvider>(context, listen: false);
    final domain = _domainController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (domain.isEmpty || apiKey.isEmpty) {
      showAppSnackBar(
        context,
        'Domain dan API Key tidak boleh kosong.',
        isError: true,
      );
      return;
    }

    provider.saveApiConfig(domain, apiKey);
    showAppSnackBar(context, 'Konfigurasi API berhasil disimpan.');
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer di sini untuk mendapatkan nilai terbaru dari provider
    return Consumer<FileProvider>(
      builder: (context, provider, child) {
        // Tentukan apakah kartu harus terbuka secara default
        final bool shouldBeExpanded =
            provider.apiDomain == null || provider.apiKey == null;

        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.settings_ethernet),
            title: const Text('Konfigurasi Server API'),
            // ==> KONTROL EXPANSION SECARA DINAMIS <==
            initiallyExpanded: shouldBeExpanded,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _domainController,
                      decoration: const InputDecoration(
                        labelText: 'Domain Server',
                        hintText: 'Contoh: http://domain.com',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _apiKeyController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan & Muat Ulang'),
                        onPressed: _saveConfig,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
