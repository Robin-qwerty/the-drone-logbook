import 'package:flutter/material.dart';
import '../database_helper.dart';

class EditFlightLogScreen extends StatefulWidget {
  final int logId;
  final VoidCallback onLogUpdated;

  const EditFlightLogScreen(
      {super.key, required this.logId, required this.onLogUpdated});

  @override
  _EditFlightLogScreenState createState() => _EditFlightLogScreenState();
}

class _EditFlightLogScreenState extends State<EditFlightLogScreen> {
  final TextEditingController _usageController = TextEditingController();
  final TextEditingController _flightTimeController = TextEditingController();
  late Map<String, dynamic> _logData;

  @override
  void initState() {
    super.initState();
    _loadFlightLogData();
  }

  @override
  void dispose() {
    _usageController.dispose();
    _flightTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadFlightLogData() async {
    final log = await DatabaseHelper().getFlightLog(widget.logId);
    if (log != null) {
      setState(() {
        _logData = log;
        _usageController.text = log['usage_count'].toString();
        _flightTimeController.text = log['flight_time_minutes'].toString();
      });
    }
  }

  Future<void> _saveChanges() async {
    final usageCount = _usageController.text;
    final flightTime = _flightTimeController.text;

    if (usageCount.isEmpty || flightTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final usageCountInt = int.tryParse(usageCount);
    final flightTimeInt = int.tryParse(flightTime);

    if (usageCountInt == null || flightTimeInt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
      );
      return;
    }

    final updatedLog = {
      'id': widget.logId,
      'battery_id': _logData['battery_id'],
      'drone_id': _logData['drone_id'],
      'flight_time_minutes': flightTimeInt,
      'usage_count': usageCountInt,
      'usage_date': _logData['usage_date'],
    };

    final result = await DatabaseHelper().updateFlightLog(updatedLog);
    if (result > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flight log updated successfully')),
      );
      widget.onLogUpdated();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update flight log')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Flight Log')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Flight Count',
                hintText: 'Enter the updated number of flights',
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
