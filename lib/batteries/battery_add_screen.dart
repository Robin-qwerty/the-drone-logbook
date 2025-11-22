import 'package:flutter/material.dart';
import '../database_helper.dart';

class BatteryFormScreen extends StatefulWidget {
  const BatteryFormScreen({super.key});

  @override
  _BatteryFormScreenState createState() => _BatteryFormScreenState();
}

class _BatteryFormScreenState extends State<BatteryFormScreen> {
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
                      TextFormField(
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
