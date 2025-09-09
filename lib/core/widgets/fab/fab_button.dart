// lib/core/widgets/fab/fab_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/settings/application/theme_provider.dart';

class FabButton extends StatelessWidget {
  final VoidCallback onPressed;
  final GestureDragUpdateCallback onPanUpdate;

  const FabButton({
    super.key,
    required this.onPressed,
    required this.onPanUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final fabSize = themeProvider.quickFabSize;
    final iconSize = fabSize * 0.5;

    return GestureDetector(
      onPanUpdate: onPanUpdate,
      child: SizedBox(
        width: fabSize,
        height: fabSize,
        child: FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: theme.colorScheme.secondary.withOpacity(
            themeProvider.quickFabBgOpacity,
          ),
          child: Text(
            themeProvider.quickFabIcon,
            style: TextStyle(fontSize: iconSize),
          ),
        ),
      ),
    );
  }
}
