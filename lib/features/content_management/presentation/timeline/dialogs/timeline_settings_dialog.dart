// lib/features/content_management/presentation/timeline/dialogs/timeline_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../discussion_timeline_provider.dart';

// Fungsi untuk menampilkan dialog
void showTimelineSettingsDialog(BuildContext context) {
  final provider = Provider.of<DiscussionTimelineProvider>(
    context,
    listen: false,
  );
  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const TimelineSettingsDialog(),
    ),
  );
}

class TimelineSettingsDialog extends StatefulWidget {
  const TimelineSettingsDialog({super.key});

  @override
  State<TimelineSettingsDialog> createState() => _TimelineSettingsDialogState();
}

class _TimelineSettingsDialogState extends State<TimelineSettingsDialog> {
  late double _discussionRadius;
  late double _pointRadius;
  // ==> STATE BARU UNTUK JARAK <==
  late double _discussionSpacing;
  late double _pointSpacing;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DiscussionTimelineProvider>(
      context,
      listen: false,
    );
    _discussionRadius = provider.discussionRadius;
    _pointRadius = provider.pointRadius;
    _discussionSpacing = provider.discussionSpacing;
    _pointSpacing = provider.pointSpacing;
  }

  void _saveSettings() {
    final provider = Provider.of<DiscussionTimelineProvider>(
      context,
      listen: false,
    );
    provider.updateAppearanceSettings(
      discussionRadius: _discussionRadius,
      pointRadius: _pointRadius,
      discussionSpacing: _discussionSpacing,
      pointSpacing: _pointSpacing,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pengaturan Tampilan Linimasa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSlider(
              label: 'Ukuran Diskusi (Lingkaran)',
              value: _discussionRadius,
              min: 3.0,
              max: 12.0,
              divisions: 9,
              onChanged: (newValue) =>
                  setState(() => _discussionRadius = newValue),
            ),
            const SizedBox(height: 16),
            _buildSlider(
              label: 'Ukuran Poin (Kotak)',
              value: _pointRadius,
              min: 2.0,
              max: 10.0,
              divisions: 8,
              onChanged: (newValue) => setState(() => _pointRadius = newValue),
            ),
            const Divider(height: 32),
            _buildSlider(
              label: 'Jarak Vertikal Diskusi',
              value: _discussionSpacing,
              min: 5.0,
              max: 25.0,
              divisions: 20,
              onChanged: (newValue) =>
                  setState(() => _discussionSpacing = newValue),
            ),
            const SizedBox(height: 16),
            _buildSlider(
              label: 'Jarak Vertikal Poin',
              value: _pointSpacing,
              min: 4.0,
              max: 20.0,
              divisions: 16,
              onChanged: (newValue) => setState(() => _pointSpacing = newValue),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _saveSettings, child: const Text('Simpan')),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
