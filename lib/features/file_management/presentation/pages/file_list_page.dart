// lib/features/file_management/presentation/pages/file_list_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/file_provider.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';

import '../layouts/desktop_layout.dart';
import '../layouts/mobile_layout.dart';

class FileListPage extends StatelessWidget {
  const FileListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FileProvider(),
      child: Consumer<FileProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: provider.isSelectionMode
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

                  if (provider.errorMessage != null &&
                      provider.rspaceFiles.isEmpty &&
                      provider.perpuskuFiles.isEmpty) {
                    return _buildErrorView(context, provider);
                  }

                  return RefreshIndicator(
                    onRefresh: () => Future.wait([
                      provider.fetchFiles(),
                      provider.fetchFiles(),
                    ]),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const double breakpoint = 800.0;
                        if (constraints.maxWidth > breakpoint) {
                          return const DesktopLayout();
                        } else {
                          return const MobileLayout();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildDefaultAppBar(BuildContext context, FileProvider provider) {
    final bool isApiConfigured =
        provider.apiDomain != null &&
        provider.apiDomain!.isNotEmpty &&
        provider.apiKey != null &&
        provider.apiKey!.isNotEmpty;

    return AppBar(
      title: const Text('File Online & Unduhan'),
      actions: [
        if (isApiConfigured)
          IconButton(
            icon: provider.isDownloading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download_for_offline_outlined),
            onPressed: provider.isDownloading
                ? null
                : () => provider.downloadAndImportAll(context),
            tooltip: 'Download & Import Semua',
          ),
      ],
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
            final confirmed =
                await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Konfirmasi Hapus'),
                    content: Text(
                      'Anda yakin ingin menghapus ${provider.selectedDownloadedFiles.length} file ini dari perangkat?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                ) ??
                false;
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
            if (!provider.errorMessage!.contains('Konfigurasi'))
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                onPressed: () => provider.fetchFiles(),
              ),
            const SizedBox(height: 24),
            ApiConfigCard(),
          ],
        ),
      ),
    );
  }
}

class ApiConfigCard extends StatefulWidget {
  @override
  State<ApiConfigCard> createState() => _ApiConfigCardState();
}

class _ApiConfigCardState extends State<ApiConfigCard> {
  late TextEditingController _domainController;
  late TextEditingController _apiKeyController;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<FileProvider>(context, listen: false);
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
    return Consumer<FileProvider>(
      builder: (context, provider, child) {
        final bool shouldBeExpanded =
            provider.apiDomain == null || provider.apiKey == null;

        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.settings_ethernet),
            title: const Text('Konfigurasi Server API'),
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
