import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:external_path/external_path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../database_helper.dart';
import '../utils/barcode_helper.dart';

class BatteryBarcodeGenerateScreen extends StatefulWidget {
  const BatteryBarcodeGenerateScreen({super.key});

  @override
  _BatteryBarcodeGenerateScreenState createState() =>
      _BatteryBarcodeGenerateScreenState();
}

class _BatteryBarcodeGenerateScreenState
    extends State<BatteryBarcodeGenerateScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _batteries = [];
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final batteries = await _dbHelper.getAllBatteries();
    final userId = await _dbHelper.getUserId();
    setState(() {
      _batteries = batteries;
      _userId = userId;
      _isLoading = false;
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _showSnackbar('Storage permission is required to save barcodes');
        return;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        _showSnackbar('Photos permission is required to save barcodes');
        return;
      }
    }
  }

  Future<void> _downloadBarcode(Map<String, dynamic> battery) async {
    await _requestPermissions();
    
    final barcodeId = battery['barcode_id']?.toString();
    if (barcodeId == null || barcodeId.isEmpty) {
      _showSnackbar('Barcode ID not found for this battery');
      return;
    }

    try {
      // Generate barcode image
      final imageBytes = await BarcodeHelper.generateBarcodeImage(
        barcodeId: barcodeId,
        title: battery['number']?.toString() ?? 'Battery',
      );

      final success = await _saveBarcodeBytes(
        imageBytes,
        'battery_${battery['id']}_$barcodeId.png',
      );
      if (success) {
        _showSnackbar('Barcode saved!');
      } else {
        _showSnackbar('Failed to save barcode');
      }
    } catch (e) {
      _showSnackbar('Error saving barcode: $e');
    }
  }

  Future<void> _downloadAllBarcodes() async {
    await _requestPermissions();

    if (_batteries.isEmpty) {
      _showSnackbar('No batteries to generate barcodes for');
      return;
    }

    final entries = _batteries
        .map((battery) {
          final code = battery['barcode_id']?.toString();
          if (code == null || code.isEmpty) {
            return null;
          }
          final label =
              battery['number']?.toString() ?? 'Battery ${battery['id']}';
          return BarcodeSheetEntry(barcodeId: code, label: label);
        })
        .whereType<BarcodeSheetEntry>()
        .toList();

    if (entries.isEmpty) {
      _showSnackbar('None of your batteries have barcodes yet.');
      return;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfFile = await BarcodeHelper.generateBarcodeSheetPdf(
        entries: entries,
        fileName: 'battery_barcodes_$timestamp.pdf',
      );

      final savedPath =
          await _savePdfFile(pdfFile, 'battery_barcodes_$timestamp.pdf');

      if (savedPath != null) {
        _showSnackbar('Barcode sheet saved to $savedPath');
      } else {
        _showSnackbar('Barcode sheet ready. Share or print it now.');
      }

      await _sharePdfFile(
        pdfFile,
        'Battery barcode sheet ready to print.',
      );
    } catch (e) {
      _showSnackbar('Error creating barcode sheet: $e');
    }
  }

  Future<void> _shareBarcode(Map<String, dynamic> battery) async {
    final barcodeId = battery['barcode_id']?.toString();
    if (barcodeId == null || barcodeId.isEmpty) {
      _showSnackbar('Barcode ID not found for this battery');
      return;
    }

    try {
      final imageBytes = await BarcodeHelper.generateBarcodeImage(
        barcodeId: barcodeId,
        title: battery['number']?.toString() ?? 'Battery',
      );

      final file = await BarcodeHelper.saveTempFile(
        imageBytes,
        'battery_${battery['id']}_$barcodeId.png',
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Battery Barcode: ${battery['number'] ?? 'Battery ${battery['id']}'}',
      );
    } catch (e) {
      _showSnackbar('Error sharing barcode: $e');
    }
  }

  Future<void> _showStandaloneBarcodeSheet() async {
    if (_userId == null) {
      final userId = await _dbHelper.getUserId();
      setState(() {
        _userId = userId;
      });
    }
    if (_userId == null) return;

    final nextSuffix = _calculateNextBarcodeSuffix();
    final codeController =
        TextEditingController(text: nextSuffix.toString().padLeft(3, '0'));
    final labelController =
        TextEditingController(text: 'Battery $nextSuffix');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final barcodeId =
                  '${_userId!}${codeController.text.padLeft(3, '0')}';
              final label = labelController.text.trim().isEmpty
                  ? 'Unassigned Battery'
                  : labelController.text.trim();
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Standalone Barcode',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Barcode suffix (3 digits)',
                        prefixIcon: Icon(Icons.tag),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label (optional)',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: barcodeId,
                            width: 280,
                            height: 80,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            barcodeId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _requestPermissions();
                              final imageBytes =
                                  await BarcodeHelper.generateBarcodeImage(
                                barcodeId: barcodeId,
                                title: label,
                              );
                              final success = await _saveBarcodeBytes(
                                imageBytes,
                                'barcode_$barcodeId.png',
                              );
                              if (success) {
                                _showSnackbar('Barcode saved!');
                              }
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final imageBytes =
                                  await BarcodeHelper.generateBarcodeImage(
                                barcodeId: barcodeId,
                                title: label,
                              );
                              final file = await BarcodeHelper.saveTempFile(
                                imageBytes,
                                'barcode_$barcodeId.png',
                              );
                              await Share.shareXFiles(
                                [XFile(file.path)],
                                text: 'Battery Barcode: $label',
                              );
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can print and attach this barcode now. When you scan it later, the app will ask to create the battery.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _generateBulkStandaloneBarcodes() async {
    if (_userId == null) {
      final userId = await _dbHelper.getUserId();
      setState(() {
        _userId = userId;
      });
    }
    if (_userId == null) return;

    final controller = TextEditingController(text: '10');
    final count = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bulk Standalone Barcodes'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: const InputDecoration(
              labelText: 'How many barcodes?',
              helperText: 'Enter the number of new barcodes you need',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                Navigator.of(context).pop(value);
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );

    if (count == null || count <= 0) {
      return;
    }

    final start = _calculateNextBarcodeSuffix();
    final entries = List<BarcodeSheetEntry>.generate(count, (index) {
      final suffix = start + index;
      final suffixPadded = suffix.toString().padLeft(3, '0');
      final barcodeId = '${_userId!}$suffixPadded';
      final label = 'Unassigned Battery $suffixPadded';
      return BarcodeSheetEntry(barcodeId: barcodeId, label: label);
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfFile = await BarcodeHelper.generateBarcodeSheetPdf(
        entries: entries,
        fileName: 'standalone_barcodes_$timestamp.pdf',
      );

      final savedPath =
          await _savePdfFile(pdfFile, 'standalone_barcodes_$timestamp.pdf');
      if (savedPath != null) {
        _showSnackbar('Standalone barcode sheet saved to $savedPath');
      } else {
        _showSnackbar('Standalone barcode sheet ready to share.');
      }
      await _sharePdfFile(
        pdfFile,
        'Standalone barcodes ready to print.',
      );
    } catch (e) {
      _showSnackbar('Error generating bulk barcodes: $e');
    }
  }

  int _calculateNextBarcodeSuffix() {
    if (_userId == null) return _batteries.length + 1;
    int maxSuffix = 0;
    for (final battery in _batteries) {
      final barcode = battery['barcode_id']?.toString();
      if (barcode == null) continue;
      if (barcode.startsWith(_userId!)) {
        final suffix = int.tryParse(barcode.substring(_userId!.length)) ?? 0;
        if (suffix > maxSuffix) {
          maxSuffix = suffix;
        }
      }
    }
    return maxSuffix + 1;
  }

  Future<bool> _saveBarcodeBytes(
    Uint8List bytes,
    String fileName, {
    bool silent = false,
  }) async {
    try {
      await BarcodeHelper.saveToGallery(bytes, fileName);
      return true;
    } catch (e) {
      if (!silent) {
        _showSnackbar('Failed to save barcode: $e');
      }
      return false;
    }
  }

  Future<String?> _savePdfFile(File pdfFile, String fileName) async {
    try {
      String targetPath;
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) return null;
        final downloadsPath =
            await ExternalPath.getExternalStoragePublicDirectory('Download');
        targetPath = '$downloadsPath/$fileName';
      } else {
        final downloadsDir = await getDownloadsDirectory();
        final documentsDir = await getApplicationDocumentsDirectory();
        final dir = downloadsDir ?? documentsDir;
        targetPath = '${dir.path}/$fileName';
      }
      final targetFile = File(targetPath);
      await targetFile.writeAsBytes(await pdfFile.readAsBytes(), flush: true);
      return targetFile.path;
    } catch (e) {
      _showSnackbar('Could not save PDF: $e');
      return null;
    }
  }

  Future<void> _sharePdfFile(File pdfFile, String message) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: message,
      );
    } catch (e) {
      _showSnackbar('Unable to share PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Barcodes'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_userId != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User ID: $_userId',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'All barcodes will start with your User ID',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showStandaloneBarcodeSheet,
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text('Generate single barcode'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _generateBulkStandaloneBarcodes,
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Bulk standalone barcodes'),
                      ),
                    ],
                  ),
                ),
                if (_batteries.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.barcode_reader,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No batteries found.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _batteries.length,
                      itemBuilder: (context, index) {
                        final battery = _batteries[index];
                        final barcodeId = battery['barcode_id']?.toString() ?? 'N/A';
                        final isWrittenOff = battery['end_date'] != null &&
                            battery['end_date'].toString().isNotEmpty;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            battery['number']?.toString() ??
                                                'Battery ${battery['id']}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              decoration: isWrittenOff
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: isWrittenOff
                                                  ? Colors.grey
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Barcode ID: $barcodeId',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Barcode display
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: BarcodeWidget(
                                      barcode: Barcode.code128(),
                                      data: barcodeId,
                                      width: 300,
                                      height: 80,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _downloadBarcode(battery),
                                      icon: const Icon(Icons.download),
                                      label: const Text('Download'),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _shareBarcode(battery),
                                      icon: const Icon(Icons.share),
                                      label: const Text('Share'),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (_batteries.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _downloadAllBarcodes,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Download All Barcodes'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

