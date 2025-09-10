// lib/core/utils/scaffold_messenger_utils.dart
import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : null,
    ),
  );
}

/// Menampilkan SnackBar khusus untuk hadiah neuron.
void showNeuronRewardSnackBar(BuildContext context, int amount) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '🎉 Kamu mendapatkan +$amount Neurons!',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.deepPurple,
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Menampilkan SnackBar khusus untuk penalti neuron.
void showNeuronPenaltySnackBar(BuildContext context, int amount) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Kamu kehilangan $amount Neurons karena menghapus data.',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.red.shade700,
      duration: const Duration(seconds: 3),
    ),
  );
}
