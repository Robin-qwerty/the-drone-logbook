import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../database_helper.dart';
import 'battery_detail_screen.dart';

class BatteryBarcodeScanScreen extends StatefulWidget {
  const BatteryBarcodeScanScreen({super.key});

  @override
  _BatteryBarcodeScanScreenState createState() =>
      _BatteryBarcodeScanScreenState();
}

class _BatteryBarcodeScanScreenState extends State<BatteryBarcodeScanScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final MobileScannerController _controller = MobileScannerController();
  String? _userId;
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await _dbHelper.getUserId();
    setState(() {
      _userId = userId;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    // Prevent processing the same barcode multiple times
    if (_isProcessing || _lastScannedCode == barcode) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedCode = barcode;
    });

    try {
      if (_userId == null) {
        await _loadUserId();
      }

      if (_userId == null) {
        _showSnackbar('User ID not found. Please restart the app.');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Check if barcode starts with user ID
      if (!barcode.startsWith(_userId!)) {
        _showSnackbar('This barcode does not belong to your account');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Try to find battery by barcode ID
      final battery = await _dbHelper.getBatteryByBarcodeId(barcode);

      if (battery != null) {
        // Battery exists, open detail screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BatteryDetailScreen(battery: battery),
            ),
          );
        }
      } else {
        // Battery doesn't exist, ask if user wants to create it
        if (mounted) {
          final shouldCreate = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Battery Not Found'),
              content: Text(
                'No battery found with barcode ID: $barcode\n\n'
                'Would you like to create a new battery with this ID?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Create Battery'),
                ),
              ],
            ),
          );

          if (shouldCreate == true) {
            // Navigate to add battery screen with pre-filled barcode ID
            if (mounted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BatteryFormScreenWithBarcode(
                    barcodeId: barcode,
                  ),
                ),
              );
              if (result == true) {
                _showSnackbar('Battery created successfully!');
              }
            }
          }
        }
      }
    } catch (e) {
      _showSnackbar('Error processing barcode: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Battery Barcode'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleBarcodeScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing barcode...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_userId != null)
                    Text(
                      'User ID: $_userId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Point your camera at a battery barcode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom battery form screen that accepts a barcode ID
class BatteryFormScreenWithBarcode extends StatefulWidget {
  final String barcodeId;

  const BatteryFormScreenWithBarcode({
    super.key,
    required this.barcodeId,
  });

  @override
  _BatteryFormScreenWithBarcodeState createState() =>
      _BatteryFormScreenWithBarcodeState();
}

class _BatteryFormScreenWithBarcodeState
    extends State<BatteryFormScreenWithBarcode> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _cellCountController = TextEditingController();
  DateTime? _buyDate;

  List<Map<String, dynamic>> _batteryTypes = [];
  int? _selectedBatteryTypeId;

  @override
  void initState() {
    super.initState();
    _loadBatteryTypes();
    // Pre-fill number with barcode ID
    _numberController.text = 'Battery ${widget.barcodeId}';
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadBatteryTypes() async {
    final types = await _dbHelper.getAllBatteryTypes();
    setState(() {
      _batteryTypes = types;
    });
  }

  Future<void> _addBattery() async {
    if (_formKey.currentState!.validate()) {
      final selectedType = _batteryTypes
          .firstWhere((type) => type['id'] == _selectedBatteryTypeId);

      final cellCount = int.parse(_cellCountController.text);
      final capacity = double.parse(_capacityController.text);
      final maxVoltage = selectedType['max_voltage'];
      final storageWatt = (cellCount * capacity * maxVoltage) / 1000 / 2; // Wh
      final fullWatt = (cellCount * capacity * maxVoltage) / 1000; // Wh
      final formattedBuyDate = _buyDate?.toIso8601String() ?? '';

      await _dbHelper.insertBattery({
        'number': _numberController.text,
        'brand': _brandController.text,
        'battery_type_id': _selectedBatteryTypeId,
        'description': _descriptionController.text,
        'buy_date': formattedBuyDate,
        'cell_count': cellCount,
        'capacity': capacity,
        'storage_watt': double.parse(storageWatt.toStringAsFixed(2)),
        'full_watt': double.parse(fullWatt.toStringAsFixed(2)),
        'barcode_id': widget.barcodeId, // Use the scanned barcode ID
      });

      _showSnackbar('Battery added successfully!');
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a Battery'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _numberController,
                        decoration: InputDecoration(
                          labelText: 'Number/name for the battery*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.label),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Number is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Barcode ID: ${widget.barcodeId}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _brandController,
                        decoration: InputDecoration(
                          labelText: 'Brand',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.business),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedBatteryTypeId,
                        decoration: InputDecoration(
                          labelText: 'Battery Type*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.battery_charging_full),
                        ),
                        items: _batteryTypes.map((type) {
                          return DropdownMenuItem<int>(
                            value: type['id'],
                            child: Text(type['type']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBatteryTypeId = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Type is required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cellCountController,
                              decoration: InputDecoration(
                                labelText: 'Cell Count*',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.layers),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Cell Count is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _capacityController,
                              decoration: InputDecoration(
                                labelText: 'Capacity (mAh)*',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.battery_std),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Capacity is required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          setState(() {
                            _buyDate = selectedDate;
                          });
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_buyDate == null
                            ? 'Select Buy Date'
                            : 'Buy Date: ${_buyDate.toString().split(' ')[0]}'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _addBattery,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'Add Battery',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

