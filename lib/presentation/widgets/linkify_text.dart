// lib/presentation/widgets/linkify_text.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Fungsi untuk menampilkan snackbar jika URL tidak valid
void _showInvalidUrlSnackbar(BuildContext context) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Tidak dapat membuka URL, format tidak valid.'),
      backgroundColor: Colors.red,
    ),
  );
}

// Widget utama yang akan kita gunakan
class LinkifyText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final TextAlign textAlign;

  const LinkifyText(
    this.text, {
    super.key,
    this.style,
    this.linkStyle,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Regex untuk mendeteksi URL
    final urlRegExp = RegExp(
      r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+',
      caseSensitive: false,
    );
    final List<TextSpan> textSpans = [];

    text.splitMapJoin(
      urlRegExp,
      onMatch: (Match match) {
        final url = match[0]!;
        textSpans.add(
          TextSpan(
            text: url,
            style:
                linkStyle ??
                TextStyle(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                try {
                  // Coba tambahkan http jika tidak ada
                  final uri = Uri.parse(
                    url.startsWith('http') ? url : 'https://$url',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    _showInvalidUrlSnackbar(context);
                  }
                } catch (e) {
                  _showInvalidUrlSnackbar(context);
                }
              },
          ),
        );
        return '';
      },
      onNonMatch: (String nonMatch) {
        // Ambil warna teks default dari tema
        final defaultColor = theme.textTheme.bodyLarge?.color;
        textSpans.add(
          TextSpan(
            text: nonMatch,
            style: style ?? TextStyle(color: defaultColor),
          ),
        );
        return '';
      },
    );

    // Gunakan DefaultTextStyle.of(context).style sebagai basis
    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: textSpans,
      ),
    );
  }
}
