// lib/presentation/pages/countdown_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/countdown_provider.dart';
import 'countdown_page/dialogs/add_countdown_dialog.dart';
import '../../data/models/countdown_model.dart';
// Import baru untuk dialog konfirmasi
import 'countdown_page/dialogs/countdown_dialogs.dart';
import 'countdown_page/dialogs/edit_countdown_dialog.dart';

class CountdownPage extends StatelessWidget {
  const CountdownPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CountdownProvider(),
      child: const _CountdownView(),
    );
  }
}

class _CountdownView extends StatelessWidget {
  const _CountdownView();

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CountdownProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hitung Mundur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.refreshTimers(),
            tooltip: 'Muat Ulang Timer',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshTimers(),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.timers.isEmpty
            ? const Center(
                child: Text('Tidak ada timer. Tekan + untuk menambah.'),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                itemCount: provider.timers.length,
                itemBuilder: (context, index) {
                  final timer = provider.timers[index];
                  // ====================== PERUBAHAN DI SINI ======================
                  // Tambahkan Key unik untuk setiap item dalam list
                  return _buildTimerCard(
                    key: ValueKey(timer.id), // Kunci unik ditambahkan
                    context: context,
                    provider: provider,
                    timer: timer,
                  );
                  // ==================== AKHIR PERUBAHAN ====================
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddCountdownDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Tambah Timer',
      ),
    );
  }

  Widget _buildTimerCard({
    // Tambahkan parameter Key
    Key? key,
    required BuildContext context,
    required CountdownProvider provider,
    required CountdownItem timer,
  }) {
    final isFinished = timer.remainingDuration.inSeconds <= 0;
    return Card(
      // Teruskan Key ke Card
      key: key,
      color: isFinished ? Colors.grey.shade300 : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    timer.name,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // ====================== PERUBAHAN DI SINI ======================
                // Tombol Edit ditambahkan di sini
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showEditCountdownDialog(context, timer),
                  tooltip: 'Ubah Timer',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    // Panggil dialog konfirmasi
                    final confirmed = await showDeleteConfirmationDialog(
                      context,
                      timer.name,
                    );
                    // Hapus hanya jika pengguna menekan "Hapus"
                    if (confirmed) {
                      provider.removeTimer(timer.id);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _formatDuration(timer.remainingDuration),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: timer.isRunning ? Theme.of(context).primaryColor : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
                  onPressed: isFinished
                      ? null
                      : () => provider.toggleTimer(timer.id),
                  iconSize: 40,
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.resetTimer(timer.id),
                  iconSize: 40,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
