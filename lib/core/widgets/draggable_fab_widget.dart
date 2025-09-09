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
  final GlobalKey _fabKey = GlobalKey();

  // 1. Tambahkan variabel state untuk melacak status menu
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

  void _showNavigationMenu() {
    // 2. Cek apakah menu sudah terbuka. Jika ya, jangan lakukan apa-apa.
    if (_isMenuOpen) return;

    // 3. Set status menjadi terbuka sebelum menampilkan menu
    setState(() {
      _isMenuOpen = true;
    });

    final BuildContext navigatorContext = navigatorKey.currentContext!;
    final RenderBox renderBox =
        _fabKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: navigatorContext,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy - size.height - 90,
        position.dx + size.width,
        position.dy,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'topics',
          child: ListTile(
            leading: Icon(Icons.topic_outlined),
            title: Text('Buka Topics'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'my_tasks',
          child: ListTile(
            leading: Icon(Icons.task_alt_outlined),
            title: Text('Buka My Tasks'),
          ),
        ),
      ],
      elevation: 8.0,
    ).then((String? value) {
      // 4. Set status menjadi tertutup SETELAH menu ditutup (baik memilih item atau tidak)
      setState(() {
        _isMenuOpen = false;
      });

      if (value == null) return;

      if (value == 'topics') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const TopicsPage()),
        );
      } else if (value == 'my_tasks') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const MyTasksPage()),
        );
      }
    });
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
          child: SizedBox(
            width: fabSize,
            height: fabSize,
            child: FloatingActionButton(
              key: _fabKey,
              onPressed: _showNavigationMenu,
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
    );
  }
}
