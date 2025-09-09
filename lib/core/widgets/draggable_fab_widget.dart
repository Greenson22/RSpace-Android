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

  void _correctPosition(Size screenSize) {
    if (_position == null) return;

    final padding = MediaQuery.of(context).padding;
    const fabSize = 56.0;

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
    // ==> 1. KONSUMSI THEMEPROVIDER
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    const fabSize = 56.0;

    _position ??= Offset(
      screenSize.width - fabSize - 20.0,
      screenSize.height - fabSize - padding.bottom - 20.0,
    );

    _correctPosition(screenSize);

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
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
        child: FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tombol FAB Cepat diklik!')),
            );
          },
          // ==> 2. GUNAKAN IKON DARI PROVIDER
          child: Text(
            themeProvider.quickFabIcon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
