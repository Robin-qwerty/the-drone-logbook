import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/barcode_helper.dart';

class BatteryBarcodeViewScreen extends StatefulWidget {
  final String barcodeId;
  final String title;

  const BatteryBarcodeViewScreen({
    super.key,
    required this.barcodeId,
    required this.title,
  });

  @override
  State<BatteryBarcodeViewScreen> createState() =>
      _BatteryBarcodeViewScreenState();
}

class _BatteryBarcodeViewScreenState extends State<BatteryBarcodeViewScreen> {
  bool _isSaving = false;

  Future<void> _ensurePermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission required to save barcode.');
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        throw Exception('Photos permission required to save barcode.');
      }
    }
  }

  Future<Uint8List> _buildImage() {
    return BarcodeHelper.generateBarcodeImage(
      barcodeId: widget.barcodeId,
      title: widget.title,
    );
  }

  Future<void> _download() async {
    try {
      setState(() => _isSaving = true);
      await _ensurePermissions();
      final bytes = await _buildImage();
      await BarcodeHelper.saveToGallery(
        bytes,
        'battery_${widget.barcodeId}.png',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barcode saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save barcode: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _share() async {
    try {
      setState(() => _isSaving = true);
      final bytes = await _buildImage();
      final file = await BarcodeHelper.saveTempFile(
        bytes,
        'battery_${widget.barcodeId}.png',
      );
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Battery Barcode: ${widget.title}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share barcode: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isSaving ? null : _share,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: widget.barcodeId,
                      width: 320,
                      height: 120,
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      widget.barcodeId,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _download,
              icon: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isSaving ? 'Saving...' : 'Download Barcode'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tip: print and stick this barcode on the battery. '
              'Scanning it will instantly open the battery or let you create it.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

