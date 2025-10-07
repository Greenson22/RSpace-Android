// lib/features/file_management/presentation/pages/file_list_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/file_provider.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../auth/presentation/profile_page.dart';
import '../../../backup_management/application/backup_provider.dart';
import '../../../settings/presentation/pages/settings_page.dart';

import '../layouts/desktop_layout.dart';
import '../layouts/mobile_layout.dart';

class FileListPage extends StatelessWidget {
  const FileListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FileProvider()),
        ChangeNotifierProvider(create: (_) => BackupProvider()),
        ChangeNotifierProvider.value(value: Provider.of<AuthProvider>(context)),
      ],
      child: Consumer<FileProvider>(
        builder: (context, provider, child) {
          final auth = Provider.of<AuthProvider>(context, listen: false);

          if (auth.authState != AuthState.authenticated) {
            return _buildLoginRequiredView(context);
          }

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

                  if (provider.errorMessage != null) {
                    return _buildErrorView(context, provider);
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchFiles(),
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

  // ==> TAMPILAN ERROR DIPERBARUI <==
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
                ).then(
                  (_) => provider.fetchFiles(),
                ); // Muat ulang setelah kembali
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget ApiConfigCard dihapus dari file ini
