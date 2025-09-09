// lib/features/dashboard/presentation/widgets/dashboard_body.dart

import 'package:flutter/material.dart';
import 'dashboard_grid.dart';
import 'dashboard_header.dart';

class DashboardBody extends StatelessWidget {
  final Key dashboardPathKey;
  final bool isKeyboardActive;
  final int focusedIndex;
  final List<VoidCallback> dashboardActions;
  final bool isPathSet;
  final Future<void> Function() onRefresh;

  const DashboardBody({
    super.key,
    required this.dashboardPathKey,
    required this.isKeyboardActive,
    required this.focusedIndex,
    required this.dashboardActions,
    required this.isPathSet,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              DashboardHeader(key: dashboardPathKey),
              const SizedBox(height: 20),
              DashboardGrid(
                isKeyboardActive: isKeyboardActive,
                focusedIndex: focusedIndex,
                dashboardActions: dashboardActions,
                isPathSet: isPathSet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
