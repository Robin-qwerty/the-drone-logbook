import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';

class BarcodeSheetEntry {
  final String barcodeId;
  final String label;

  const BarcodeSheetEntry({
    required this.barcodeId,
    required this.label,
  });
}

class BarcodeHelper {
  static Future<Uint8List> generateBarcodeImage({
    required String barcodeId,
    required String title,
  }) async {
    final screenshotController = ScreenshotController();
    final widget = Material(
      color: Colors.white,
      child: Container(
        width: 400,
        height: 220,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            BarcodeWidget(
              barcode: Barcode.code128(),
              data: barcodeId,
              width: 360,
              height: 110,
              color: Colors.black,
            ),
            const SizedBox(height: 12),
            Text(
              barcodeId,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );

    return screenshotController.captureFromWidget(
      widget,
      pixelRatio: 3.0,
      delay: const Duration(milliseconds: 150),
    );
  }

  static pw.Widget _buildPdfBarcodeCell(BarcodeSheetEntry entry) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            entry.label,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.BarcodeWidget(
            barcode: pw.Barcode.code128(),
            data: entry.barcodeId,
            width: 150,
            height: 60,
            drawText: false,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            entry.barcodeId,
            style: pw.TextStyle(
              font: pw.Font.courier(),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  static Future<File> generateBarcodeSheetPdf({
    required List<BarcodeSheetEntry> entries,
    int columns = 2,
    String fileName = 'battery_barcodes.pdf',
  }) async {
    final pdf = pw.Document();
    final gridChildren = entries.map(_buildPdfBarcodeCell).toList();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.GridView(
            crossAxisCount: columns,
            childAspectRatio: 1.25,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: gridChildren,
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> saveToGallery(Uint8List bytes, String fileName) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Gal.putImageBytes(bytes, name: fileName);
    } else {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        final file = File('${downloads.path}/$fileName');
        await file.writeAsBytes(bytes);
      }
    }
  }

  static Future<File> saveTempFile(Uint8List bytes, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

