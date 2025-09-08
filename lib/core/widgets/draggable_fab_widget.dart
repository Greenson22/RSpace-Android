// lib/core/widgets/draggable_fab_widget.dart
import 'package:flutter/material.dart';

class DraggableFab extends StatefulWidget {
  const DraggableFab({super.key});

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  // Variabel untuk menyimpan posisi FAB.
  // Dibuat nullable agar kita tahu kapan harus menginisialisasinya.
  Offset? _position;

  // Fungsi untuk memeriksa dan mengoreksi posisi FAB jika berada di luar batas.
  // Ini akan dipanggil setiap kali ukuran layar berubah.
  void _correctPosition(Size screenSize) {
    if (_position == null) return;

    final padding = MediaQuery.of(context).padding;
    const fabSize = 56.0; // Ukuran standar FloatingActionButton

    // Hitung posisi baru yang valid
    final double correctedX = _position!.dx.clamp(
      padding.left,
      screenSize.width - fabSize - padding.right,
    );
    final double correctedY = _position!.dy.clamp(
      padding.top,
      screenSize.height - fabSize - padding.bottom,
    );

    final correctedPosition = Offset(correctedX, correctedY);

    // Jika posisi saat ini tidak sama dengan posisi yang dikoreksi,
    // update state agar FAB pindah ke posisi yang benar.
    if (_position != correctedPosition) {
      // Menggunakan addPostFrameCallback untuk menghindari error "setState() called during build".
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _position = correctedPosition;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    const fabSize = 56.0;

    // Inisialisasi posisi awal di pojok kanan bawah jika belum ada.
    _position ??= Offset(
      screenSize.width - fabSize - 20.0,
      screenSize.height - fabSize - padding.bottom - 20.0,
    );

    // Panggil fungsi koreksi setiap kali widget di-build ulang (termasuk saat resize).
    _correctPosition(screenSize);

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // Update posisi berdasarkan pergerakan jari.
            _position = _position! + details.delta;

            // Batasi juga posisi saat sedang digeser.
            _position = Offset(
              _position!.dx.clamp(
                padding.left,
                screenSize.width - fabSize - padding.right,
              ),
              _position!.dy.clamp(
                padding.top,
                screenSize.height - fabSize - padding.bottom,
              ),
            );
          });
        },
        child: FloatingActionButton(
          onPressed: () {
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
