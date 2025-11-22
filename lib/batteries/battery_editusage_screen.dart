import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'package:intl/intl.dart';

class BatteryEditUsageScreen extends StatefulWidget {
  final int usageId;
  final VoidCallback onUsageUpdated;

  const BatteryEditUsageScreen({
    super.key,
    required this.usageId,
    required this.onUsageUpdated,
  });

  @override
  _BatteryEditUsageScreenState createState() => _BatteryEditUsageScreenState();
}

class _BatteryEditUsageScreenState extends State<BatteryEditUsageScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _usageController = TextEditingController();
  final TextEditingController _flightTimeController = TextEditingController();
  DateTime _usageDate = DateTime.now();
  int? _selectedDroneId;
  List<Map<String, dynamic>> _drones = [];
  late Map<String, dynamic> _usageData;

  @override
  void initState() {
    super.initState();
    _loadFlightLogData();
    _loadDrones();
  }

  Future<void> _loadFlightLogData() async {
    final log = await _dbHelper.getFlightLog(widget.usageId);
    if (log != null) {
      setState(() {
        _usageData = log;
        _usageController.text = log['usage_count'].toString();
        _flightTimeController.text = log['flight_time_minutes'].toString();
        _selectedDroneId = log['drone_id'];
        if (log['usage_date'] != null) {
          try {
            _usageDate = DateFormat('yyyy-MM-dd').parse(log['usage_date']);
          } catch (e) {
            // If parsing fails, keep the default date
            _usageDate = DateTime.now();
          }
        }
      });
    }
  }

  Future<void> _loadDrones() async {
    final drones = await _dbHelper.getDrones();
    setState(() {
      _drones = [
        {'id': 0, 'name': 'Other'},
        ...drones.map((drone) => {
              'id': drone['id'],
              'name': drone['name'].toString(),
            })
      ];
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _saveChanges() async {
    if (_usageController.text.isEmpty || _flightTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    final usageCount = int.tryParse(_usageController.text);
    final flightTime = int.tryParse(_flightTimeController.text);
    if (usageCount == null || flightTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers.')),
      );
      return;
    }

    final updatedUsage = {
      'id': widget.usageId,
      'battery_id': _usageData['battery_id'],
      'drone_id': _selectedDroneId,
      'usage_count': usageCount,
      'flight_time_minutes': flightTime,
      'usage_date': _formatDate(_usageDate),
    };

    final result = await _dbHelper.updateFlightLog(updatedUsage);
    if (result > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usage updated successfully.')),
      );
      widget.onUsageUpdated();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update usage.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Battery Cycle/Usage')),
      body: Padding(
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
                  child: Text(drone['id'] == 0
                    ? 'Other'
                    : '${drone['id']} - ${drone['name']}'),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cycle/Usage Count',
                hintText: 'Enter the updated cycle/usage count',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _flightTimeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Flight Time (minutes)',
                hintText: 'Enter the updated total flight time',
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
              onPressed: _saveChanges,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
