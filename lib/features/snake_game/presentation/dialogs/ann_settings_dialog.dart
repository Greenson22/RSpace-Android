// lib/features/snake_game/presentation/dialogs/ann_settings_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../application/snake_game_provider.dart';

void showAnnSettingsDialog(BuildContext context) {
  final provider = Provider.of<SnakeGameProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const AnnSettingsDialog(),
    ),
  );
}

class AnnSettingsDialog extends StatefulWidget {
  const AnnSettingsDialog({super.key});

  @override
  State<AnnSettingsDialog> createState() => _AnnSettingsDialogState();
}

class _AnnSettingsDialogState extends State<AnnSettingsDialog> {
  late List<TextEditingController> _hiddenLayerControllers;
  late List<int> _layers;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SnakeGameProvider>(context, listen: false);
    _layers = List.from(provider.annLayers);
    _hiddenLayerControllers = _layers
        .sublist(1, _layers.length - 1)
        .map((size) => TextEditingController(text: size.toString()))
        .toList();
  }

  @override
  void dispose() {
    for (var controller in _hiddenLayerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addLayer() {
    setState(() {
      _hiddenLayerControllers.add(TextEditingController(text: '8'));
    });
  }

  void _removeLayer(int index) {
    if (_hiddenLayerControllers.length > 1) {
      setState(() {
        _hiddenLayerControllers[index].dispose();
        _hiddenLayerControllers.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus ada satu hidden layer.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _resetToDefault() {
    setState(() {
      for (var controller in _hiddenLayerControllers) {
        controller.dispose();
      }
      _hiddenLayerControllers = [TextEditingController(text: '12')];
    });
  }

  void _saveSettings() {
    final provider = Provider.of<SnakeGameProvider>(context, listen: false);
    final List<int> newHiddenLayers = _hiddenLayerControllers
        .map((c) => int.tryParse(c.text) ?? 8)
        .where((val) => val > 0) // Pastikan neuron lebih dari 0
        .toList();

    if (newHiddenLayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harus ada setidaknya satu hidden layer dengan neuron > 0.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newFullLayers = [10, ...newHiddenLayers, 4];
    provider.setAnnLayers(newFullLayers);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Arsitektur ANN diubah. Otak terbaik sebelumnya telah direset.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atur Arsitektur ANN'),
      content: SizedBox(
        width: 400, // Beri lebar agar tidak terlalu sempit
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLayerCard(
                'Input Layer (Sensor)',
                '${_layers.first} Neuron',
                Icons.sensors,
                Theme.of(context).colorScheme.secondary,
                isEditable: false,
              ),
              _buildFlowConnector(),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        leading: Icon(Icons.layers),
                        title: Text(
                          'Hidden Layers',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        dense: true,
                      ),
                      ..._hiddenLayerControllers.asMap().entries.map((entry) {
                        int index = entry.key;
                        TextEditingController controller = entry.value;
                        return _buildEditableLayer(
                          'Layer ${index + 1}',
                          controller,
                          () => _removeLayer(index),
                        );
                      }),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: _addLayer,
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah'),
                          ),
                          TextButton.icon(
                            onPressed: _resetToDefault,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildFlowConnector(),
              _buildLayerCard(
                'Output Layer (Arah)',
                '${_layers.last} Neuron',
                Icons.exit_to_app,
                Theme.of(context).colorScheme.primary,
                isEditable: false,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: const Text('Simpan & Reset Otak'),
        ),
      ],
    );
  }

  Widget _buildFlowConnector() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Center(child: Icon(Icons.arrow_downward, color: Colors.grey)),
    );
  }

  Widget _buildLayerCard(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor, {
    bool isEditable = true,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildEditableLayer(
    String title,
    TextEditingController controller,
    VoidCallback onRemove,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 0.0, 4.0),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                suffixText: 'Neuron',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
