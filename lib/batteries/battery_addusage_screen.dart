import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'package:intl/intl.dart';

class BatteryAddUsageScreen extends StatefulWidget {
  final int batteryId;

  const BatteryAddUsageScreen({super.key, required this.batteryId});

  @override
  _BatteryAddUsageScreenState createState() => _BatteryAddUsageScreenState();
}

class _BatteryAddUsageScreenState extends State<BatteryAddUsageScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _usageController = TextEditingController();
  final TextEditingController _flightTimeController = TextEditingController();
  DateTime _usageDate = DateTime.now();
  int? _selectedDroneId;
  List<Map<String, dynamic>> _drones = [];

  @override
  void initState() {
    super.initState();
    _loadDrones();
  }

  Future<void> _loadDrones() async {
    final drones = await _dbHelper.getDrones();

    setState(() {
      _drones = [
        {'id': 0, 'name': 'Other'},
        ...drones
            .where((drone) => drone['id'] != null && drone['name'] != null)
            .map((drone) => {
                  'id': drone['id'],
                  'name': drone['name'].toString(),
                })
      ];
    });
  }

  @override
  void dispose() {
    _usageController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _addUsage() async {
    if (_usageController.text.isEmpty || _flightTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a cycle/usage count.')),
      );
      return;
    }

    final usageCount = int.tryParse(_usageController.text);
    final flightTime = _flightTimeController.text;
    if (usageCount == null || usageCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid cycle/usage count.')),
      );
      return;
    }

    if (_selectedDroneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a drone used.')),
      );
      return;
    }

    await _dbHelper.insertUsage(
      widget.batteryId,
      _selectedDroneId!,
      _formatDate(_usageDate),
      flightTime,
      usageCount,
    );

    _usageController.clear();
    _flightTimeController.clear();
    setState(() {
      _selectedDroneId = null;
      _usageDate = DateTime.now();
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Battery Cycle/Usage')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<int>(
              hint: const Text('Select a drone'),
              value: _selectedDroneId,
              onChanged: (int? newDroneId) {
                setState(() {
                  _selectedDroneId = newDroneId;
                });
              },
              items: _drones.map((drone) {
                return DropdownMenuItem<int>(
                  value: drone['id'],
                  child: Text(drone['id'] == 0 ? 'Other' : drone['name']),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cycle/Usage Count',
                hintText: 'Enter the cycle/usage count for today',
              ),
            ),
            const SizedBox(height: 16),
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
                  'Usage Date: ${_formatDate(_usageDate)}',
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
              onPressed: _addUsage,
              child: const Text('Add Cycle/Usage'),
            ),
          ],
        ),
      ),
    );
  }
}
