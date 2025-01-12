import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';

class BatteryAddUsageScreen extends StatefulWidget {
  final int batteryId;

  BatteryAddUsageScreen({required this.batteryId});

  @override
  _BatteryAddUsageScreenState createState() => _BatteryAddUsageScreenState();
}

class _BatteryAddUsageScreenState extends State<BatteryAddUsageScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _usageController = TextEditingController();
  DateTime _usageDate = DateTime.now();

  @override
  void dispose() {
    _usageController.dispose();
    super.dispose();
  }

  // Format the date to display
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Save the usage for the selected battery
  Future<void> _addUsage() async {
    if (_usageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a cycle/usage count.')),
      );
      return;
    }

    final usageCount = int.tryParse(_usageController.text);
    if (usageCount == null || usageCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid cycle/usage count.')),
      );
      return;
    }

    // Use the batteryId passed into the widget
    await _dbHelper.insertUsage(
      widget.batteryId,
      _formatDate(_usageDate),
      usageCount,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('cycle/Usage added successfully!')),
    );

    _usageController.clear();

    // Navigate back to the BatteryDetailScreen
    Navigator.pop(context); // This pops the current screen and returns to the previous one
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Battery cycle/Usage')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Usage Count Field
            TextField(
              controller: _usageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'cycle/Usage Count',
                hintText: 'Enter the cycle/usage count for today',
              ),
            ),
            const SizedBox(height: 16),

            // Date Picker for Usage Date
            Row(
              children: [
                Text(
                  'cycle/Usage Date: ${_formatDate(_usageDate)}',
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
                    if (pickedDate != null && pickedDate != _usageDate) {
                      setState(() {
                        _usageDate = pickedDate;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Add Usage Button
            ElevatedButton(
              onPressed: _addUsage,
              child: const Text('Add cycle/Usage'),
            ),
          ],
        ),
      ),
    );
  }
}
