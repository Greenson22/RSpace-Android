import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class PdfViewerPage extends StatelessWidget {
  final String htmlContent;
  final String pageTitle;
  final String subjectPath;

  const PdfViewerPage({
    super.key,
    required this.htmlContent,
    required this.pageTitle,
    required this.subjectPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
        ),
        elevation: 2,
      ),
      // PdfPreview akan me-render dokumen PDF secara realtime dan interaktif di dalam aplikasi
      body: PdfPreview(
        build: (PdfPageFormat format) async => await Printing.convertHtml(
          format: format,
          html: htmlContent,
          baseUrl: Uri.file(
            subjectPath,
          ).toString(), // Mengamankan rendering gambar lokal
        ),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: true,
        canChangeOrientation: true,
        initialPageFormat: PdfPageFormat.a4,
        previewPageMargin: const EdgeInsets.all(16),
      ),
    );
  }
}
