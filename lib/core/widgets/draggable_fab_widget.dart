// lib/core/widgets/draggable_fab_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/settings/application/theme_provider.dart';
import '../../features/content_management/presentation/topics/topics_page.dart';
import '../../features/my_tasks/presentation/pages/my_tasks_page.dart';
import '../../main.dart';

class DraggableFab extends StatefulWidget {
  const DraggableFab({super.key});

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  Offset? _position;
  bool _isMenuOpen = false;

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

  Widget _buildPopupMenu() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return const SizedBox.shrink();

    return SizedBox(
      width: 220,
      child: Card(
        elevation: 8.0,
        // Hapus margin bawah karena posisi diatur oleh Stack
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                setState(() => _isMenuOpen = false);
                navigator.push(
                  MaterialPageRoute(builder: (_) => const TopicsPage()),
                );
              },
              child: const ListTile(
                leading: Icon(Icons.topic_outlined),
                title: Text('Buka Topics'),
                dense: true,
              ),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: () {
                setState(() => _isMenuOpen = false);
                navigator.push(
                  MaterialPageRoute(builder: (_) => const MyTasksPage()),
                );
              },
              child: const ListTile(
                leading: Icon(Icons.task_alt_outlined),
                title: Text('Buka My Tasks'),
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final fabSize = themeProvider.quickFabSize;
    final iconSize = fabSize * 0.5;

    _position ??= Offset(
      screenSize.width - fabSize - 20.0,
      screenSize.height - fabSize - padding.bottom - 20.0,
    );

    _correctPosition(screenSize, fabSize);

    // Tentukan apakah FAB berada di sisi kiri layar
    final bool isFabOnLeft = _position!.dx < (screenSize.width / 2);

    return Transform.translate(
      offset: _position!,
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
          // ==> PERUBAHAN UTAMA: Gunakan Stack, bukan Column <==
          child: Stack(
            clipBehavior: Clip.none, // Izinkan menu tampil di luar batas Stack
            alignment: Alignment.center,
            children: [
              // Widget FAB, ini akan menjadi pusat dari Stack
              SizedBox(
                width: fabSize,
                height: fabSize,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _isMenuOpen = !_isMenuOpen;
                    });
                  },
                  backgroundColor: theme.colorScheme.secondary.withOpacity(
                    themeProvider.quickFabBgOpacity,
                  ),
                  child: Text(
                    themeProvider.quickFabIcon,
                    style: TextStyle(fontSize: iconSize),
                  ),
                ),
              ),

              // Tampilkan menu secara kondisional
              if (_isMenuOpen)
                // Gunakan Positioned untuk menempatkan menu di kiri atau kanan FAB
                Positioned(
                  // Jika FAB di kiri, tampilkan menu di kanan. Jika FAB di kanan, tampilkan di kiri.
                  left: isFabOnLeft ? fabSize + 12.0 : null,
                  right: !isFabOnLeft ? fabSize + 12.0 : null,
                  // Posisikan menu di tengah secara vertikal relatif terhadap FAB
                  top: fabSize / 2,
                  // Gunakan Transform untuk menyesuaikan titik pivot menu
                  child: Transform.translate(
                    offset: const Offset(
                      0,
                      -55,
                    ), // Sesuaikan agar tengah menu sejajar tengah FAB
                    child: _buildPopupMenu(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
