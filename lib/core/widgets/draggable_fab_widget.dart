// lib/core/widgets/draggable_fab_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/settings/application/theme_provider.dart';

class DraggableFab extends StatefulWidget {
  const DraggableFab({super.key});

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  Offset? _position;

  // ==> 1. PERBARUI FUNGSI KOREKSI UNTUK MENERIMA UKURAN DINAMIS
  void _correctPosition(Size screenSize, double fabSize) {
    if (_position == null) return;

    final padding = MediaQuery.of(context).padding;

    final double correctedX = _position!.dx.clamp(
      padding.left,
      screenSize.width - fabSize - padding.right,
    );
    final double correctedY = _position!.dy.clamp(
      padding.top,
      screenSize.height - fabSize - padding.bottom,
    );

    final correctedPosition = Offset(correctedX, correctedY);

    if (_position != correctedPosition) {
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    // ==> 2. AMBIL UKURAN DARI PROVIDER
    final fabSize = themeProvider.quickFabSize;
    // ==> 3. HITUNG UKURAN IKON BERDASARKAN UKURAN FAB
    final iconSize = fabSize * 0.5; // Ikon akan menjadi 50% dari ukuran FAB

    _position ??= Offset(
      screenSize.width - fabSize - 20.0,
      screenSize.height - fabSize - padding.bottom - 20.0,
    );

    // ==> 4. KIRIM UKURAN SAAT MEMANGGIL FUNGSI KOREKSI
    _correctPosition(screenSize, fabSize);

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: Opacity(
        opacity: themeProvider.quickFabOverallOpacity,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _position = _position! + details.delta;
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
          // ==> 5. BUNGKUS FAB DENGAN SIZEDBOX AGAR UKURANNYA BISA DIATUR
          child: SizedBox(
            width: fabSize,
            height: fabSize,
            child: FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tombol FAB Cepat diklik!')),
                );
              },
              backgroundColor: theme.colorScheme.secondary.withOpacity(
                themeProvider.quickFabBgOpacity,
              ),
              child: Text(
                themeProvider.quickFabIcon,
                // ==> 6. GUNAKAN UKURAN IKON YANG SUDAH DIHITUNG
                style: TextStyle(fontSize: iconSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
