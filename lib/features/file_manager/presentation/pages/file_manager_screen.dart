import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class FileManagerScreen extends StatefulWidget {
  final String initialDirectory;

  const FileManagerScreen({super.key, required this.initialDirectory});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  late String _currentDir;
  List<FileSystemEntity> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDir = widget.initialDirectory;
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);
    try {
      final dir = Directory(_currentDir);
      if (await dir.exists()) {
        final List<FileSystemEntity> entities = await dir.list().toList();

        // Urutkan: Folder di atas, lalu file. Kemudian urut sesuai abjad.
        entities.sort((a, b) {
          final isADir = a is Directory;
          final isBDir = b is Directory;
          if (isADir && !isBDir) return -1;
          if (!isADir && isBDir) return 1;
          return p
              .basename(a.path)
              .toLowerCase()
              .compareTo(p.basename(b.path).toLowerCase());
        });

        setState(() {
          _items = entities;
        });
      } else {
        _showError('Direktori tidak ditemukan!');
      }
    } catch (e) {
      _showError('Gagal memuat direktori: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Navigasi masuk ke sub-folder
  void _openDirectory(Directory dir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileManagerScreen(initialDirectory: dir.path),
      ),
    ).then((_) => _loadDirectory()); // Refresh saat kembali
  }

  // Membuat Folder Baru
  Future<void> _createNewFolder() async {
    final TextEditingController controller = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Folder Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nama Folder'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buat'),
          ),
        ],
      ),
    );

    if (confirm == true && controller.text.trim().isNotEmpty) {
      try {
        final newDir = Directory(p.join(_currentDir, controller.text.trim()));
        if (!(await newDir.exists())) {
          await newDir.create();
          _loadDirectory();
        } else {
          _showError('Folder dengan nama tersebut sudah ada.');
        }
      } catch (e) {
        _showError('Gagal membuat folder: $e');
      }
    }
  }

  // Mengubah nama file/folder
  Future<void> _renameEntity(FileSystemEntity entity) async {
    final bool isDir = entity is Directory;
    final String oldName = p.basename(entity.path);
    final TextEditingController controller = TextEditingController(
      text: oldName,
    );

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ganti Nama ${isDir ? 'Folder' : 'File'}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nama Baru'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirm == true &&
        controller.text.trim().isNotEmpty &&
        controller.text.trim() != oldName) {
      try {
        final String newPath = p.join(
          p.dirname(entity.path),
          controller.text.trim(),
        );
        await entity.rename(newPath);
        _loadDirectory();
      } catch (e) {
        _showError('Gagal mengganti nama: $e');
      }
    }
  }

  // Menghapus file/folder
  Future<void> _deleteEntity(FileSystemEntity entity) async {
    final bool isDir = entity is Directory;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${isDir ? 'folder' : 'file'} "${p.basename(entity.path)}"? ${isDir ? '\nSemua isi di dalamnya juga akan terhapus.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await entity.delete(
          recursive: true,
        ); // recursive: true wajib untuk menghapus folder yang ada isinya
        _loadDirectory();
      } catch (e) {
        _showError('Gagal menghapus: $e');
      }
    }
  }

  void _showActionMenu(FileSystemEntity entity) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Ganti Nama'),
              onTap: () {
                Navigator.pop(context);
                _renameEntity(entity);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteEntity(entity);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('File Manager (Debug)', style: TextStyle(fontSize: 16)),
            Text(
              _currentDir,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Buat Folder Baru',
            onPressed: _createNewFolder,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDirectory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('Folder Kosong'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final FileSystemEntity entity = _items[index];
                final bool isDir = entity is Directory;
                final String name = p.basename(entity.path);

                return ListTile(
                  leading: Icon(
                    isDir ? Icons.folder : Icons.insert_drive_file,
                    color: isDir ? Colors.orange : Colors.blueGrey,
                    size: 32,
                  ),
                  title: Text(name),
                  subtitle: isDir
                      ? null
                      : Text(
                          '${File(entity.path).lengthSync()} bytes',
                          style: const TextStyle(fontSize: 12),
                        ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showActionMenu(entity),
                  ),
                  onTap: () {
                    if (isDir) {
                      _openDirectory(entity as Directory);
                    } else {
                      // TODO: Implementasi open file viewer jika diperlukan
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Hanya folder yang bisa dibuka navigasinya.',
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
