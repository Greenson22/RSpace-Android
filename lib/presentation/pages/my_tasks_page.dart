import 'package:flutter/material.dart';

class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: const Center(
        child: Text(
          'Halaman Tugas Saya - Segera Hadir!',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
