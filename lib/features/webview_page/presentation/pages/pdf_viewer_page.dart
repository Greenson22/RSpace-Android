// lib/features/webview_page/presentation/pages/pdf_viewer_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// ==> 1. HAPUS IMPORT PRINTING, GANTI DENGAN SYNCFUSION PDF VIEWER <==
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// Import dependencies yang diperlukan untuk dialog diskusi dan snackbar
import 'package:my_aplication/features/content_management/discussions/models/discussion_model.dart';
import 'dialogs/discussion_details_dialog.dart';
import 'dialogs/add_point_dialog_webview.dart';
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart';

class PdfViewerPage extends StatefulWidget {
  final String htmlContent;
  final String pageTitle;
  final String subjectPath;
  final Discussion? discussion; // Tambahkan parameter discussion

  const PdfViewerPage({
    super.key,
    required this.htmlContent,
    required this.pageTitle,
    required this.subjectPath,
    this.discussion, // Inisialisasi di konstruktor
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
    final bool isFromDiscussion = widget.discussion != null;

    // --- SKALA UKURAN APPBAR UNTUK MOBILE (Disamakan dengan WebViewPage & TopicsPage) ---
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double baseAppBarIconSize = 20.0;
    final scaledAppBarIconSize = baseAppBarIconSize * textScaleFactor;

    // --- INTEGRASI TEMA DINAMIS ---
    final theme = Theme.of(context);
    final Color appBarForegroundColor =
        theme.appBarTheme.foregroundColor ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.primaryColor,
        foregroundColor: appBarForegroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        iconTheme: IconThemeData(
          size: scaledAppBarIconSize,
          color: appBarForegroundColor,
        ),
        title: Text(
          widget.pageTitle,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          // Tampilkan tombol Tambah Poin & Edit Detail jika berasal dari diskusi
          if (isFromDiscussion) ...[
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              iconSize: scaledAppBarIconSize,
              color: appBarForegroundColor,
              tooltip: 'Tambah Poin',
              onPressed: () {
                showAddPointDialogFromWebView(
                  context: context,
                  discussion: widget.discussion!,
                  onPointAdded: () {
                    showAppSnackBar(context, 'Poin berhasil ditambahkan.');
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_note),
              iconSize: scaledAppBarIconSize,
              color: appBarForegroundColor,
              tooltip: 'Edit Detail & Poin',
              onPressed: () =>
                  showDiscussionDetailsDialog(context, widget.discussion!),
            ),
          ],
          const SizedBox(width: 12.0),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ==> 2. UBAH METODE INI UNTUK MENGGUNAKAN SFPDFVIEWER <==
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

    // Menggunakan SfPdfViewer untuk merender data bytes PDF dari memori
    return SfPdfViewer.memory(
      _pdfBytes!,
      enableDoubleTapZooming: true, // Izinkan double tap zoom di mobile
      interactionMode: PdfInteractionMode.pan, // Mode geser dasar
    );
  }
}
