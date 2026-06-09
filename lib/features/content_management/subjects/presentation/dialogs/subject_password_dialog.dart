// lib/features/content_management/presentation/subjects/dialogs/subject_password_dialog.dart

import 'package:flutter/material.dart';

// Enum to define the purpose of the dialog
enum PasswordDialogMode { set, enter, remove }

// Function to show the dialog
Future<String?> showSubjectPasswordDialog({
  required BuildContext context,
  required String subjectName,
  required PasswordDialogMode mode,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _PasswordDialog(subjectName: subjectName, mode: mode),
  );
}

// The dialog widget itself
class _PasswordDialog extends StatefulWidget {
  final String subjectName;
  final PasswordDialogMode mode;

  const _PasswordDialog({required this.subjectName, required this.mode});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getTitle() {
    switch (widget.mode) {
      case PasswordDialogMode.set:
        return 'Kunci Subject';
      case PasswordDialogMode.enter:
        return 'Buka Kunci Subject';
      case PasswordDialogMode.remove:
        return 'Hapus Kunci Subject';
    }
  }

  String _getActionButtonText() {
    switch (widget.mode) {
      case PasswordDialogMode.set:
        return 'Kunci';
      case PasswordDialogMode.enter:
        return 'Buka';
      case PasswordDialogMode.remove:
        return 'Hapus Kunci';
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getTitle()),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Masukkan kata sandi untuk subject "${widget.subjectName}".',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                autofocus: true,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kata sandi tidak boleh kosong.';
                  }
                  if (widget.mode == PasswordDialogMode.set &&
                      value.length < 4) {
                    return 'Kata sandi minimal 4 karakter.';
                  }
                  return null;
                },
              ),
              if (widget.mode == PasswordDialogMode.set) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureText,
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi Kata Sandi',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Kata sandi tidak cocok.';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _submit, child: Text(_getActionButtonText())),
      ],
    );
  }
}
