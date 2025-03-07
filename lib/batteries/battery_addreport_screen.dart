import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'package:intl/intl.dart';

class BatteryAddReportScreen extends StatefulWidget {
  final int batteryId;

  const BatteryAddReportScreen({super.key, required this.batteryId});

  @override
  _BatteryAddReportScreenState createState() => _BatteryAddReportScreenState();
}

class _BatteryAddReportScreenState extends State<BatteryAddReportScreen> {
  final _reportController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // List of default report options
  final List<String> _defaultReports = [
    'Battery under 3.0V',
    'Battery under 2.5V',
    'Battery over 4.2V',
    'Battery overheating',
    'Battery swelling',
    'Battery dent',
    'Battery involved in a crash(without damage)',
    'Battery involved in a crash(with damage)',
    'Battery connector damaged',
  ];

  String? _selectedReport;
  bool _isCustomReport = false;
  DateTime _reportDate = DateTime.now();

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  // Function to save the report to the database
  Future<void> _saveReport() async {
    final reportText =
        _isCustomReport ? _reportController.text : _selectedReport;

    if (reportText == null || reportText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a report text')));
      return;
    }

    await _dbHelper.insertReport(widget.batteryId, reportText, _reportDate);

    Navigator.pop(context);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              hint: const Text('Select a report type'),
              value: _selectedReport,
              onChanged: (String? newReport) {
                setState(() {
                  _selectedReport = newReport;
                  _isCustomReport =
                      false;
                  _reportController.clear();
                });
              },
              items: _defaultReports.map((String report) {
                return DropdownMenuItem<String>(
                  value: report,
                  child: Text(report),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Checkbox(
                  value: _isCustomReport,
                  onChanged: (bool? newValue) {
                    setState(() {
                      _isCustomReport = newValue!;
                      _selectedReport =
                          null;
                      _reportController
                          .clear();
                    });
                  },
                ),
                const Text('Use custom report'),
              ],
            ),
            if (_isCustomReport) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reportController,
                decoration: const InputDecoration(
                  labelText: 'Custom Report Text',
                  hintText: 'Enter your custom report here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
              ),
            ],
            const SizedBox(height: 20),

            Row(
              children: [
                Text(
                  'Report Date: ${_formatDate(_reportDate)}',
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _reportDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null && pickedDate != _reportDate) {
                      setState(() {
                        _reportDate = pickedDate;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveReport,
              child: const Text('Save Report'),
            ),
          ],
        ),
      ),
    );
  }
}
