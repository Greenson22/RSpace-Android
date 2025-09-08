// lib/presentation/pages/dashboard_page/widgets/dashboard_header.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/path_service.dart';

// ... (kode DashboardHeader tidak berubah)
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang!',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<DateTime>(
            stream: Stream.periodic(
              const Duration(seconds: 1),
              (_) => DateTime.now(),
            ),
            builder: (context, snapshot) {
              final now = snapshot.data ?? DateTime.now();
              final date = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
              final time = DateFormat('HH:mm:ss').format(now);
              return Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text(date, style: Theme.of(context).textTheme.bodyMedium),
                  const Spacer(),
                  Text(
                    time,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          const _DashboardPath(),
        ],
      ),
    );
  }
}

class _DashboardPath extends StatefulWidget {
  const _DashboardPath();

  @override
  State<_DashboardPath> createState() => _DashboardPathState();
}

class _DashboardPathState extends State<_DashboardPath> {
  final PathService _pathService = PathService();
  Future<String>? _pathFuture;

  @override
  void initState() {
    super.initState();
    _pathFuture = _getPath();
  }

  Future<String> _getPath() async {
    return _pathService.contentsPath;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _pathFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Memuat path...');
        }
        if (snapshot.hasError) return const Text('Gagal memuat path.');
        if (snapshot.hasData) {
          // ==> PERUBAHAN DI SINI <==
          final theme = Theme.of(context);
          final TextStyle? textStyle;

          if (kDebugMode) {
            // Jika dalam mode debug, gunakan warna kuning dan tebalkan.
            textStyle = theme.textTheme.bodySmall?.copyWith(
              color: Colors.amber.shade800,
              fontWeight: FontWeight.bold,
            );
          } else {
            // Jika dalam mode rilis, gunakan warna primer tema.
            textStyle = theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            );
          }

          return Row(
            children: [
              const Icon(Icons.folder_outlined, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  snapshot.data!,
                  style: textStyle, // DIUBAH
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
