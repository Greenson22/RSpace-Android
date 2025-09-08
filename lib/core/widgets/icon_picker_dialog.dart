// lib/presentation/widgets/icon_picker_dialog.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/settings/application/services/gemini_service.dart';

// Fungsi utama sekarang memanggil widget dialog
Future<void> showIconPickerDialog({
  required BuildContext context,
  required String name,
  required Function(String) onIconSelected,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        IconPickerDialog(name: name, onIconSelected: onIconSelected),
  );
}

// Widget dialog diubah menjadi StatefulWidget
class IconPickerDialog extends StatefulWidget {
  final String name;
  final Function(String) onIconSelected;

  const IconPickerDialog({
    super.key,
    required this.name,
    required this.onIconSelected,
  });

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  final TextEditingController _iconController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  Future<List<String>>? _geminiSuggestions;

  @override
  void initState() {
    super.initState();
    _fetchGeminiSuggestions();
  }

  void _fetchGeminiSuggestions() {
    setState(() {
      _geminiSuggestions = _geminiService.suggestIcon(name: widget.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<String>>>(
      future: _loadManualIcons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Dialog(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Gagal memuat ikon.'),
            actions: [
              TextButton(
                child: const Text('Tutup'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        }

        final iconCategories = snapshot.data!;

        return AlertDialog(
          title: const Text('Pilih Ikon Baru'),
          content: DefaultTabController(
            length: iconCategories.length,
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGeminiRecommendationSection(),
                  _buildManualInputSection(),
                  TabBar(
                    isScrollable: true,
                    tabs: iconCategories.keys
                        .map((title) => Tab(text: title))
                        .toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: iconCategories.entries.map((entry) {
                        return _buildIconGrid(entry.value);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  // Widget untuk bagian rekomendasi AI
  Widget _buildGeminiRecommendationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rekomendasi AI untuk "${widget.name}"',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchGeminiSuggestions,
                tooltip: 'Muat Ulang Rekomendasi',
              ),
            ],
          ),
          FutureBuilder<List<String>>(
            future: _geminiSuggestions,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Gagal memuat: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('Tidak ada saran.');
              }
              return Wrap(
                spacing: 16,
                children: snapshot.data!.map((icon) {
                  return InkWell(
                    onTap: () {
                      widget.onIconSelected(icon);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(icon, style: const TextStyle(fontSize: 32)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  // Widget untuk input manual
  Widget _buildManualInputSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
      child: TextField(
        controller: _iconController,
        decoration: InputDecoration(
          labelText: 'Atau ketik ikon di sini',
          suffixIcon: IconButton(
            icon: const Icon(Icons.done),
            onPressed: () {
              if (_iconController.text.isNotEmpty) {
                widget.onIconSelected(_iconController.text);
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  // Widget untuk grid ikon manual
  Widget _buildIconGrid(List<String> icons) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final iconSymbol = icons[index];
        return InkWell(
          onTap: () {
            widget.onIconSelected(iconSymbol);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: Text(iconSymbol, style: const TextStyle(fontSize: 32)),
          ),
        );
      },
    );
  }

  // Fungsi helper untuk memuat ikon dari JSON
  Future<Map<String, List<String>>> _loadManualIcons() async {
    final String response = await rootBundle.loadString('assets/icons.json');
    final data = await json.decode(response) as Map<String, dynamic>;
    return data.map((key, value) {
      return MapEntry(key, List<String>.from(value as List));
    });
  }
}
