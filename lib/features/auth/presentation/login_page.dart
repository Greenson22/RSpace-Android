// lib/features/auth/presentation/login_page.dart

import 'dart:async'; // <-- Import async
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../application/auth_provider.dart';
import '../../dashboard/presentation/pages/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ==> STATE BARU UNTUK TIMER <==
  Timer? _cooldownTimer;
  int _cooldownSeconds = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _canResend = false;
      _cooldownSeconds = 60;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        _cooldownTimer?.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.login(_emailController.text, _passwordController.text);

    if (authProvider.loginStatus == LoginStatus.success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
        (route) => false,
      );
      authProvider.resetLoginStatus();
    } else if (authProvider.loginMessage.contains('belum diverifikasi')) {
      // Jika error karena belum verifikasi, aktifkan tombol resend
      setState(() {
        _canResend = true;
      });
    }
  }

  // ==> FUNGSI BARU UNTUK KIRIM ULANG <==
  Future<void> _handleResend() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan email Anda terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _startCooldown();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.resendVerification(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Cek apakah pesan error adalah tentang verifikasi
        final bool showResendButton =
            auth.loginStatus == LoginStatus.error &&
            auth.loginMessage.contains('belum diverifikasi');

        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🚀', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 16),
                      Text(
                        'Selamat Datang di RSpace',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan login untuk melanjutkan',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),

                      if (auth.loginStatus != LoginStatus.idle)
                        _buildStatusWidget(auth.loginStatus, auth.loginMessage),

                      if (auth.loginStatus != LoginStatus.loading &&
                          auth.loginStatus != LoginStatus.success) ...[
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value!.isEmpty
                              ? 'Email tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) => value!.isEmpty
                              ? 'Password tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Login'),
                          ),
                        ),
                        // ==> TAMPILKAN TOMBOL KIRIM ULANG SECARA KONDISIONAL <==
                        if (showResendButton) ...[
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _canResend ? _handleResend : null,
                            child: Text(
                              _canResend
                                  ? 'Kirim Ulang Email Verifikasi'
                                  : 'Kirim Ulang dalam ($_cooldownSeconds detik)',
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusWidget(LoginStatus status, String message) {
    Widget icon;
    Color color;

    switch (status) {
      case LoginStatus.loading:
        icon = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 3),
        );
        color = Colors.blue;
        break;
      case LoginStatus.success:
        icon = const Icon(Icons.check_circle, color: Colors.green);
        color = Colors.green;
        break;
      case LoginStatus.error:
        icon = const Icon(Icons.error, color: Colors.red);
        color = Colors.red;
        break;
      case LoginStatus.idle:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
