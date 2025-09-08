// lib/core/widgets/draggable_fab_widget.dart
import 'package:flutter/material.dart';

class DraggableFab extends StatefulWidget {
  const DraggableFab({super.key});

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  // Atur posisi awal FAB di pojok kanan bawah
  late Offset _position;
  bool _isPositionInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inisialisasi posisi berdasarkan ukuran layar
    // Ini dilakukan di sini agar kita memiliki akses ke context
    if (!_isPositionInitialized) {
      final screenSize = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding;
      setState(() {
        _position = Offset(
          screenSize.width - 56 - 20, // 56 (lebar FAB) + 20 (padding)
          screenSize.height -
              56 -
              padding.bottom -
              20, // 56 (tinggi FAB) + padding bawah + 20 (padding)
        );
        _isPositionInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jika posisi belum diinisialisasi, tampilkan container kosong
    if (!_isPositionInitialized) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // Update posisi berdasarkan pergerakan jari
            _position += details.delta;

            // Batasi posisi agar tidak keluar dari area aman layar
            _position = Offset(
              _position.dx.clamp(
                padding.left,
                screenSize.width - 56 - padding.right,
              ),
              _position.dy.clamp(
                padding.top,
                screenSize.height - 56 - padding.bottom,
              ),
            );
          });
        },
        child: FloatingActionButton(
          onPressed: () {
            // TODO: Tambahkan fungsi yang Anda inginkan di sini
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tombol FAB Cepat diklik!')),
            );
          },
          child: const Icon(Icons.add_task_outlined),
        ),
      ),
    );
  }
}
