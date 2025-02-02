import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'package:intl/intl.dart';

class DroneAddFlightLogScreen extends StatefulWidget {
  final int droneId;

  const DroneAddFlightLogScreen({super.key, required this.droneId});

  @override
  _DroneAddFlightLogScreenState createState() =>
      _DroneAddFlightLogScreenState();
}

class _DroneAddFlightLogScreenState extends State<DroneAddFlightLogScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _usageController = TextEditingController();
  final TextEditingController _flightTimeController = TextEditingController();
  DateTime _usageDate = DateTime.now();
  int? _selectedBatteryId;
  List<Map<String, dynamic>> _batteries = [];

  @override
  void initState() {
    super.initState();
    _loadBatteries();
  }

  Future<void> _loadBatteries() async {
    final batteries = await _dbHelper.getBatteries();
    setState(() {
      _batteries = [
        {'id': 0, 'brand': 'Other', 'number': ''},
        ...batteries
      ];
    });
  }

  @override
  void dispose() {
    _usageController.dispose();
    _flightTimeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _addFlightLog() async {
    if (_usageController.text.isEmpty || _flightTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a flight count.')),
      );
      return;
    }

    final usageCount = int.tryParse(_usageController.text);
    final flightTime = _flightTimeController.text;
    if (usageCount == null || usageCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid flight count.')),
      );
      return;
    }

    if (_selectedBatteryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a battery used for the flight.')),
      );
      return;
    }

    await _dbHelper.insertFlightLog(
      widget.droneId,
      _selectedBatteryId!,
      _formatDate(_usageDate),
      flightTime,
      usageCount,
    );

    _usageController.clear();
    _flightTimeController.clear();
    setState(() {
      _selectedBatteryId = null;
      _usageDate = DateTime.now();
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Flight Log')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<int>(
              hint: const Text('Select a battery'),
              value: _selectedBatteryId,
              onChanged: (int? newBatteryId) {
                setState(() {
                  _selectedBatteryId = newBatteryId;
                });
              },
              items: _batteries.map((battery) {
                return DropdownMenuItem<int>(
                  value: battery['id'],
                  child: Text(battery['id'] == 0
                      ? 'Other'
                      : '${battery['brand']} - ${battery['number']}'),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Flight Count',
                hintText: 'Enter the number of flights today',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _flightTimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Flight Time (minutes)',
                hintText: 'Enter the total minutes flown',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Flight Date: ${_formatDate(_usageDate)}',
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _usageDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _usageDate = pickedDate;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addFlightLog,
              child: const Text('Add Flight Log'),
            ),
          ],
        ),
      ),
    );
  }
}
