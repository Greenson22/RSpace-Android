// lib/features/data_center/presentation/widgets/local_sharing_tab.dart

import 'dart:io';
import 'package:flutter/material.dart';

class LocalSharingTab extends StatefulWidget {
  final VoidCallback onSendFile;
  final VoidCallback onReceiveFile;
  final List<File> serverBackupFiles;
  final Function(File) onDeleteServerBackup;
  final Function(File) onRestoreAllZip;

  const LocalSharingTab({
    super.key,
    required this.onSendFile,
    required this.onReceiveFile,
    required this.serverBackupFiles,
    required this.onDeleteServerBackup,
    required this.onRestoreAllZip,
  });

  @override
  State<LocalSharingTab> createState() => _LocalSharingTabState();
}

class _LocalSharingTabState extends State<LocalSharingTab> {
  // Deklarasi variabel state untuk manajemen hapus masal berkas server
  bool _isServerSelectionMode = false;
  final List<File> _selectedServerFiles = [];

  // === DIPERBAIKI: Menggunakan parameter variabel dinamis tanpa hardcode const ===
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
                // Hapus 'const' dari Row agar bisa memasukkan variabel judul dinamis
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Text(title), // Menggunakan variabel title
              ],
            ),
            content: Text(content), // Menggunakan variabel content
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
    return ListView(
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        onPressed: widget.onSendFile,
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
                        onPressed: widget.onReceiveFile,
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
        // Bagian Header Daftar Berkas Server & Tombol Dinamis
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
                                widget.serverBackupFiles.length
                            ? Icons.deselect
                            : Icons.select_all,
                        size: 18,
                        color: Colors.teal[700],
                      ),
                      tooltip:
                          _selectedServerFiles.length ==
                              widget.serverBackupFiles.length
                          ? 'Batal Semua'
                          : 'Pilih Semua',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      onPressed: () {
                        setState(() {
                          if (_selectedServerFiles.length ==
                              widget.serverBackupFiles.length) {
                            _selectedServerFiles.clear();
                          } else {
                            _selectedServerFiles.clear();
                            _selectedServerFiles.addAll(
                              widget.serverBackupFiles,
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
                                widget.onDeleteServerBackup(
                                  File('trigger_refresh_after_bulk_delete'),
                                );
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
        // Daftar Berkas yang Diterima dari Server
        widget.serverBackupFiles.isEmpty
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
                itemCount: widget.serverBackupFiles.length,
                itemBuilder: (context, index) {
                  final file = widget.serverBackupFiles[index];
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
                                      borderRadius: BorderRadius.circular(16),
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
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Ya, Restore All',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                            if (confirm) {
                              widget.onRestoreAllZip(file);
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
                        : const Icon(Icons.cloud_download, color: Colors.teal),
                    title: Text(fileName),
                    trailing: _isServerSelectionMode
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => widget.onDeleteServerBackup(file),
                          ),
                  );
                },
              ),
      ],
    );
  }
}
