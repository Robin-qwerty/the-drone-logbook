import 'package:flutter/material.dart';
import '../database_helper.dart';

class BatteryFormScreen extends StatefulWidget {
  @override
  _BatteryFormScreenState createState() => _BatteryFormScreenState();
}

class _BatteryFormScreenState extends State<BatteryFormScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _cellCountController = TextEditingController();
  DateTime? _buyDate;

  List<Map<String, dynamic>> _batteryTypes = [];
  int? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    _loadBatteryTypes();
  }

  Future<void> _loadBatteryTypes() async {
    final types = await _dbHelper.getAllBatteryTypes();
    setState(() {
      _batteryTypes = types;
    });
  }

  Future<void> _addBattery() async {
    if (_formKey.currentState!.validate()) {
      final selectedType =
          _batteryTypes.firstWhere((type) => type['id'] == _selectedTypeId);

      // Calculating storage_watt and full_watt
      final cellCount = int.parse(_cellCountController.text);
      final capacity = double.parse(_capacityController.text);
      // final storageVoltage = selectedType['storage_voltage'];
      final maxVoltage = selectedType['max_voltage'];

      final storageWatt = (cellCount * capacity * maxVoltage) / 1000 / 2; // Wh
      final fullWatt = (cellCount * capacity * maxVoltage) / 1000; // Wh

      // Ensure buyDate and endDate are not null and properly formatted
      final formattedBuyDate = _buyDate?.toIso8601String() ?? '';

      await _dbHelper.insertBattery({
        'number': _numberController.text,
        'brand': _brandController.text,
        'type_id': _selectedTypeId,
        'buy_date': formattedBuyDate,
        'end_date': '',
        'cell_count': cellCount,
        'capacity': capacity,
        'storage_watt': double.parse(storageWatt.toStringAsFixed(2)),
        'full_watt': double.parse(fullWatt.toStringAsFixed(2)),
      });

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Battery')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                      labelText: 'Number/name for the battery*'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Number is required'
                      : null,
                ),
                TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(labelText: 'Brand'),
                ),
                DropdownButtonFormField<int>(
                  value: _selectedTypeId,
                  decoration: const InputDecoration(labelText: 'Type*'),
                  items: _batteryTypes.map((type) {
                    return DropdownMenuItem<int>(
                      value: type['id'],
                      child: Text(type['type']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTypeId = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Type is required' : null,
                ),
                TextFormField(
                  controller: _cellCountController,
                  decoration: const InputDecoration(labelText: 'Cell Count*'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Cell Count is required'
                      : null,
                ),
                TextFormField(
                  controller: _capacityController,
                  decoration:
                      const InputDecoration(labelText: 'Capacity (mAh)*'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Capacity is required'
                      : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
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
                        child: Text(_buyDate == null
                            ? 'Select Buy Date'
                            : 'Buy Date: ${_buyDate.toString().split(' ')[0]}'),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addBattery,
                  child: const Text('Add Battery'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
