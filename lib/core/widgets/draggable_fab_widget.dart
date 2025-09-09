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
  Offset _position = const Offset(0, 0);
  bool _isInit = true;
  Offset _menuOpenPosition = const Offset(0, 0);
  bool _isMenuOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final screenSize = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding;
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final fabSize = themeProvider.quickFabSize;

      setState(() {
        _position = Offset(
          screenSize.width - fabSize - 20.0,
          screenSize.height - fabSize - padding.bottom - 20.0,
        );
        _isInit = false;
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

    // Memastikan posisi FAB selalu berada di dalam layar
    final double correctedX = _position.dx.clamp(
      padding.left,
      screenSize.width - fabSize - padding.right,
    );
    final double correctedY = _position.dy.clamp(
      padding.top,
      screenSize.height - fabSize - padding.bottom,
    );
    if (_position.dx != correctedX || _position.dy != correctedY) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _position = Offset(correctedX, correctedY);
          });
        }
      });
    }

    // Menentukan posisi menu berdasarkan posisi FAB saat menu dibuka
    final bool isFabOnLeft = _menuOpenPosition.dx < (screenSize.width / 2);
    const animationDuration = Duration(milliseconds: 200);

    // Widget utama diubah menjadi Stack untuk memisahkan FAB dan Menu
    return Stack(
      children: [
        // Menu navigasi yang diposisikan secara absolut
        AnimatedPositioned(
          duration: animationDuration,
          left: isFabOnLeft
              ? (_isMenuOpen
                    ? _menuOpenPosition.dx + fabSize + 12.0
                    : _menuOpenPosition.dx + fabSize / 2)
              : null,
          right: !isFabOnLeft
              ? (_isMenuOpen
                    ? screenSize.width - _menuOpenPosition.dx - fabSize - 12.0
                    : screenSize.width - _menuOpenPosition.dx - fabSize / 2)
              : null,
          // Sesuaikan posisi vertikal menu agar sejajar dengan tengah FAB
          top: _menuOpenPosition.dy + (fabSize / 2) - 55,
          child: AnimatedOpacity(
            duration: animationDuration,
            opacity: _isMenuOpen ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_isMenuOpen,
              child: _buildPopupMenu(),
            ),
          ),
        ),

        // FAB yang dapat digeser
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: Opacity(
            opacity: themeProvider.quickFabOverallOpacity,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _position = _position + details.delta;
                });
              },
              child: SizedBox(
                width: fabSize,
                height: fabSize,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _isMenuOpen = !_isMenuOpen;
                      // Simpan posisi FAB saat ini jika menu dibuka
                      if (_isMenuOpen) {
                        _menuOpenPosition = _position;
                      }
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
            ),
          ),
        ),
      ],
    );
  }
}
