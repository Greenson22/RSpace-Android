// lib/presentation/pages/backup_management_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/backup_provider.dart';
import 'backup_management_page/layouts/desktop_layout.dart';
import 'backup_management_page/layouts/mobile_layout.dart';
import 'backup_management_page/utils/backup_dialogs.dart';

class BackupManagementPage extends StatefulWidget {
  const BackupManagementPage({super.key});

  @override
  State<BackupManagementPage> createState() => _BackupManagementPageState();
}

class _BackupManagementPageState extends State<BackupManagementPage> {
  final FocusNode _focusNode = FocusNode();
  Timer? _focusTimer;
  bool _isKeyboardActive = false;
  int _focusedColumn = 0; // 0 for RSpace, 1 for PerpusKu
  int _focusedIndex = -1; // -1 for buttons, >=0 for files

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusTimer?.cancel();
    super.dispose();
  }

  // Hapus _handleKeyEvent dari sini

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BackupProvider(),
      child: Consumer<BackupProvider>(
        builder: (context, provider, child) {
          // Definisikan handler di dalam builder
          void handleKeyEvent(RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
              setState(() {
                _isKeyboardActive = true;
                _focusTimer?.cancel();
                _focusTimer = Timer(const Duration(milliseconds: 800), () {
                  if (mounted) setState(() => _isKeyboardActive = false);
                });
              });

              final rspaceFileCount = provider.rspaceBackupFiles.length;
              final perpuskuFileCount = provider.perpuskuBackupFiles.length;

              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                setState(() {
                  if (_focusedColumn == 0) {
                    // RSpace Column
                    if (_focusedIndex < rspaceFileCount - 1) _focusedIndex++;
                  } else {
                    // PerpusKu Column
                    if (_focusedIndex < perpuskuFileCount - 1) _focusedIndex++;
                  }
                });
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                setState(() {
                  if (_focusedIndex > -1) _focusedIndex--;
                });
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                setState(() {
                  if (_focusedColumn == 0) _focusedColumn = 1;
                });
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                setState(() {
                  if (_focusedColumn == 1) _focusedColumn = 0;
                });
              } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                File? selectedFile;
                if (_focusedIndex >= 0) {
                  if (_focusedColumn == 0 && _focusedIndex < rspaceFileCount) {
                    selectedFile = provider.rspaceBackupFiles[_focusedIndex];
                  } else if (_focusedColumn == 1 &&
                      _focusedIndex < perpuskuFileCount) {
                    selectedFile = provider.perpuskuBackupFiles[_focusedIndex];
                  }
                }
                if (selectedFile != null) {
                  provider.toggleFileSelection(selectedFile);
                }
              } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
                if (provider.isSelectionMode) {
                  provider.clearSelection();
                } else {
                  Navigator.of(context).pop();
                }
              }
            }
          }

          return RawKeyboardListener(
            focusNode: _focusNode,
            onKey: handleKeyEvent, // Gunakan handler yang baru
            child: Scaffold(
              appBar: provider.isSelectionMode
                  ? _buildSelectionAppBar(context, provider)
                  : AppBar(
                      title: const Text('Manajemen Backup'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.sort),
                          onPressed: () => showSortDialog(context),
                          tooltip: 'Urutkan File',
                        ),
                      ],
                    ),
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

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        const double breakpoint = 1000.0;
                        final focusProps = {
                          'isKeyboardActive': _isKeyboardActive,
                          'focusedColumn': _focusedColumn,
                          'focusedIndex': _focusedIndex,
                        };

                        if (constraints.maxWidth > breakpoint) {
                          return DesktopLayout(focusProps: focusProps);
                        } else {
                          return MobileLayout(focusProps: focusProps);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildSelectionAppBar(BuildContext context, BackupProvider provider) {
    return AppBar(
      title: Text('${provider.selectedFiles.length} dipilih'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => provider.clearSelection(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: () {
            provider.selectAllFiles([
              ...provider.rspaceBackupFiles,
              ...provider.perpuskuBackupFiles,
            ]);
          },
          tooltip: 'Pilih Semua',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => deleteSelectedFiles(context, []),
          tooltip: 'Hapus Pilihan',
        ),
      ],
    );
  }
}
