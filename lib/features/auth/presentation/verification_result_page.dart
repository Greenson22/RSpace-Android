// lib/features/auth/presentation/verification_result_page.dart
import 'package:flutter/material.dart';
import 'login_page.dart';

class VerificationResultPage extends StatelessWidget {
  final bool isSuccess;
  final String? errorMessage;

  const VerificationResultPage({
    super.key,
    required this.isSuccess,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: isSuccess ? Colors.green : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                isSuccess ? 'Verifikasi Berhasil!' : 'Verifikasi Gagal',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSuccess
                    ? 'Akun Anda telah berhasil diaktifkan. Silakan login untuk melanjutkan.'
                    : errorMessage ??
                          'Token tidak valid atau sudah kedaluwarsa. Silakan coba daftar kembali.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text('Kembali ke Halaman Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
