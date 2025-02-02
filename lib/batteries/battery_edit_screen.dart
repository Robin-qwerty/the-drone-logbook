import 'package:flutter/material.dart';
import '../database_helper.dart';

class BatteryEditScreen extends StatefulWidget {
  final Map<String, dynamic> battery;

  const BatteryEditScreen({super.key, required this.battery});

  @override
  _BatteryEditScreenState createState() => _BatteryEditScreenState();
}

class _BatteryEditScreenState extends State<BatteryEditScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numberController;
  late TextEditingController _brandController;
  late TextEditingController _descriptionController;
  late TextEditingController _capacityController;
  late TextEditingController _cellCountController;
  DateTime? _buyDate;

  List<Map<String, dynamic>> _batteryTypes = [];
  String? _selectedBatteryTypeId;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: widget.battery['number']);
    _brandController = TextEditingController(text: widget.battery['brand']);
    _descriptionController =
        TextEditingController(text: widget.battery['description']);
    _capacityController =
        TextEditingController(text: widget.battery['capacity'].toString());
    _cellCountController =
        TextEditingController(text: widget.battery['cell_count'].toString());
    _loadBatteryTypes();
    _selectedBatteryTypeId = widget.battery['battery_type_id']?.toString();
    _buyDate = DateTime.tryParse(widget.battery['buy_date']);
  }

  Future<void> _loadBatteryTypes() async {
    final types = await _dbHelper.getAllBatteryTypes();
    setState(() {
      _batteryTypes = types;
    });
  }

  void _saveBattery() async {
    if (_formKey.currentState!.validate()) {
      final capacityValue = double.tryParse(_capacityController.text) ?? 0.0;
      final cellCount = int.tryParse(_cellCountController.text) ?? 0;
      final formattedBuyDate = _buyDate?.toIso8601String() ?? '';

      await _dbHelper.updateBattery(
        widget.battery['id'],
        _numberController.text,
        _brandController.text,
        _descriptionController.text,
        _selectedBatteryTypeId ?? '1',
        capacityValue,
        formattedBuyDate,
        cellCount,
      );
      const SnackBar(
        content: Text('Battery edit successfully!'),
        duration: Duration(seconds: 2),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Battery')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: 'Battery Number'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required field' : null,
              ),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Brand'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'description'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedBatteryTypeId,
                decoration: const InputDecoration(labelText: 'Battery Type'),
                items: _batteryTypes
                    .map((type) => DropdownMenuItem<String>(
                          value: type['id'].toString(),
                          child: Text(type['type']),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBatteryTypeId = value;
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select a type'
                    : null,
              ),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity (mAh)'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null ||
                        value.isEmpty ||
                        double.tryParse(value) == null
                    ? 'Enter a valid number'
                    : null,
              ),
              TextFormField(
                controller: _cellCountController,
                decoration: const InputDecoration(labelText: 'Cell Count'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null ||
                        value.isEmpty ||
                        int.tryParse(value) == null
                    ? 'Enter a valid number'
                    : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _buyDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            _buyDate = selectedDate;
                          });
                        }
                      },
                      child: Text(_buyDate == null
                          ? 'Select Buy Date'
                          : 'Buy Date: ${_buyDate.toString().split(' ')[0]}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveBattery,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
