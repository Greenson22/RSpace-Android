// lib/presentation/pages/3_discussions_page/widgets/discussion_stats_header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/discussion_provider.dart';

class DiscussionStatsHeader extends StatefulWidget {
  const DiscussionStatsHeader({super.key});

  @override
  State<DiscussionStatsHeader> createState() => _DiscussionStatsHeaderState();
}

class _DiscussionStatsHeaderState extends State<DiscussionStatsHeader> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final theme = Theme.of(context);

    final total = provider.totalDiscussionCount;
    final finished = provider.finishedDiscussionCount;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      // MODIFIKASI: Mengecilkan margin luar Card agar selaras dengan list item
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 2),
      clipBehavior: Clip.antiAlias,
      elevation: 1, // Lebih flat khas mobile
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ), // Menyelaraskan border radius ke 8
      child: Theme(
        // Menghilangkan deviasi padding/garis pembatas bawaan ExpansionTile agar lebih rapat
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const PageStorageKey('discussion-stats-header'),
          initiallyExpanded: _isExpanded,
          // MODIFIKASI: Menyesuaikan tile padding internal agar compact
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 10.0,
            vertical: 0.0,
          ),
          onExpansionChanged: (isExpanded) {
            setState(() {
              _isExpanded = isExpanded;
            });
          },
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Ringkasan Subject',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize:
                        14.0, // MODIFIKASI: Diperkecil dari titleLarge bawaan desktop
                  ),
                ),
              ),
              // Ringkasan total info statistik di sebelah kanan
              Text.rich(
                TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize:
                        12.0, // MODIFIKASI: Diperkecil agar muat sebaris layar HP
                  ),
                  children: [
                    const TextSpan(text: 'Total: '),
                    TextSpan(
                      text: '$total',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' ('),
                    TextSpan(
                      text: '$finished ✔',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const TextSpan(text: ')'),
                  ],
                ),
              ),
            ],
          ),
          children: const [
            // Bagian children dikosongkan sesuai dengan struktur kode Anda sebelumnya.
          ],
        ),
      ),
    );
  }
}
