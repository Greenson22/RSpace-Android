// lib/core/widgets/draggable_fab_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/settings/application/theme_provider.dart';
import 'fab/fab_button.dart';
import 'fab/fab_menu_card.dart';

class DraggableFabView extends StatefulWidget {
  const DraggableFabView({super.key});

  @override
  State<DraggableFabView> createState() => _DraggableFabViewState();
}

class _DraggableFabViewState extends State<DraggableFabView> {
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

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuOpenPosition = _position;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final fabSize = themeProvider.quickFabSize;

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

    final bool isFabOnLeft = _menuOpenPosition.dx < (screenSize.width / 2);
    const animationDuration = Duration(milliseconds: 200);

    return Stack(
      children: [
        // Latar belakang transparan untuk menutup menu saat diklik di luar
        if (_isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleMenu,
              child: Container(color: Colors.transparent),
            ),
          ),

        // Menu
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
          top: _menuOpenPosition.dy + (fabSize / 2) - 55,
          child: AnimatedOpacity(
            duration: animationDuration,
            opacity: _isMenuOpen ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_isMenuOpen,
              child: FabMenuCard(
                closeMenu: () => setState(() => _isMenuOpen = false),
              ),
            ),
          ),
        ),

        // Tombol FAB
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: Opacity(
            opacity: themeProvider.quickFabOverallOpacity,
            child: FabButton(
              onPressed: _toggleMenu,
              onPanUpdate: (details) {
                setState(() {
                  _position = _position + details.delta;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
