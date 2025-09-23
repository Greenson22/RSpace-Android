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
    setState(() {
      _hiddenLayerControllers[index].dispose();
      _hiddenLayerControllers.removeAt(index);
    });
  }

  void _resetToDefault() {
    setState(() {
      _hiddenLayerControllers.forEach((c) => c.dispose());
      _hiddenLayerControllers = [TextEditingController(text: '12')];
    });
  }

  void _saveSettings() {
    final provider = Provider.of<SnakeGameProvider>(context, listen: false);
    final List<int> newHiddenLayers = _hiddenLayerControllers
        .map((c) => int.tryParse(c.text) ?? 8)
        .toList();

    // Layer input (10) + hidden layers + layer output (4)
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
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLayerInfo('Input Layer (Sensor)', _layers.first, false),
              const Divider(),
              ..._hiddenLayerControllers.asMap().entries.map((entry) {
                int index = entry.key;
                TextEditingController controller = entry.value;
                return _buildEditableLayer(
                  'Hidden Layer ${index + 1}',
                  controller,
                  () => _removeLayer(index),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addLayer,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Hidden Layer'),
              ),
              const Divider(),
              _buildLayerInfo('Output Layer (Arah)', _layers.last, false),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _resetToDefault, child: const Text('Reset')),
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

  Widget _buildLayerInfo(String title, int neuronCount, bool isEditable) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        '$neuronCount Neuron',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEditableLayer(
    String title,
    TextEditingController controller,
    VoidCallback onRemove,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
