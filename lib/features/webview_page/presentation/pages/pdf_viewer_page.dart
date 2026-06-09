// lib/features/webview_page/presentation/pages/pdf_viewer_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfViewerPage extends StatefulWidget {
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
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  Uint8List? _pdfBytes;
  bool _isGenerating = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generatePdfFromLinuxNative();
  }

  Future<void> _generatePdfFromLinuxNative() async {
    try {
      // 1. Buat file HTML sementara di direktori temp Linux
      final tempHtmlFile = File(
        '${Directory.systemTemp.path}/temp_print_${DateTime.now().millisecondsSinceEpoch}.html',
      );
      await tempHtmlFile.writeAsString(widget.htmlContent);

      // 2. Tentukan jalur luaran untuk file biner PDF sementara
      final tempPdfPath =
          '${Directory.systemTemp.path}/temp_output_${DateTime.now().millisecondsSinceEpoch}.pdf';

      ProcessResult result;

      // 3. Periksa ketersediaan WeasyPrint (Opsi Utama: Mendukung standardisasi CSS modern)
      final checkWeasyPrint = await Process.run('which', ['weasyprint']);
      if (checkWeasyPrint.exitCode == 0) {
        result = await Process.run('weasyprint', [
          tempHtmlFile.path,
          tempPdfPath,
          '--base-url',
          widget
              .subjectPath, // Memastikan gambar lokal relatif dapat ter-render
        ]);
      } else {
        // 4. Fallback ke wkhtmltopdf jika WeasyPrint belum dipasang di Linux
        final checkWkhtml = await Process.run('which', ['wkhtmltopdf']);
        if (checkWkhtml.exitCode == 0) {
          result = await Process.run('wkhtmltopdf', [
            '--enable-local-file-access',
            tempHtmlFile.path,
            tempPdfPath,
          ]);
        } else {
          throw Exception(
            "Fungsionalitas konverter PDF tidak ditemukan pada sistem Linux Anda.\n\n"
            "Silakan pasang salah satu dependensi berikut via terminal Linux:\n"
            "sudo apt install weasyprint\n"
            "atau\n"
            "sudo apt install wkhtmltopdf",
          );
        }
      }

      // 5. Validasi status eksekusi proses CLI sistem operasi
      if (result.exitCode != 0) {
        throw Exception(
          "Gagal merender dokumen di tingkat OS Linux: ${result.stderr}",
        );
      }

      // 6. Baca dokumen biner PDF hasil generate ke dalam memori aplikasi
      final pdfFile = File(tempPdfPath);
      if (!await pdfFile.exists()) {
        throw Exception("File biner PDF gagal terbentuk oleh sistem Linux.");
      }

      final bytes = await pdfFile.readAsBytes();

      // 7. Lakukan pembersihan file sampah temporary di sistem berkas Linux
      if (await tempHtmlFile.exists()) await tempHtmlFile.delete();
      if (await pdfFile.exists()) await pdfFile.delete();

      setState(() {
        _pdfBytes = bytes;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pageTitle,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
        ),
        elevation: 2,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isGenerating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Menjalankan konversi pustaka native Linux...",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Dokumen PDF yang terkunci byte datanya ditampilkan interaktif langsung di dalam aplikasi
    return PdfPreview(
      build: (format) async => _pdfBytes!,
      allowPrinting: true,
      allowSharing: true,
      canChangePageFormat:
          false, // Dikunci karena kalkulasi dimensi dilakukan di awal oleh biner Linux
      previewPageMargin: const EdgeInsets.all(16),
    );
  }
}
