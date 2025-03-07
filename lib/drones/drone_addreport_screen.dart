import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'package:intl/intl.dart';

class DroneAddReportScreen extends StatefulWidget {
  final int droneId;

  const DroneAddReportScreen({super.key, required this.droneId});

  @override
  _DroneAddReportScreenState createState() => _DroneAddReportScreenState();
}

class _DroneAddReportScreenState extends State<DroneAddReportScreen> {
  final _reportController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // List of default report options for drones
  final List<String> _defaultReports = [
    'Drone battery malfunction',
    'Drone motor failure',
    'Drone collision damage',
    'Drone GPS malfunction',
    'Drone overheating',
    'Drone signal loss',
    'Drone crash',
  ];

  String? _selectedReport;
  bool _isCustomReport = false; // Flag to toggle custom report
  DateTime _reportDate = DateTime.now(); // Default date is today's date

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

    // Insert the report into the database
    await _dbHelper.insertDroneReport(widget.droneId, reportText, _reportDate);

    Navigator.pop(context);
  }

  // Format the date to display
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Drone Report')),
      body: SingleChildScrollView(
        // Wrap the body in a scrollable view
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown for selecting a predefined report
            DropdownButton<String>(
              hint: const Text('Select a report type'),
              value: _selectedReport,
              onChanged: (String? newReport) {
                setState(() {
                  _selectedReport = newReport;
                  _isCustomReport =
                      false; // Switch off custom report if a default is selected
                  _reportController.clear(); // Clear the custom report text
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

            // Option for custom report
            Row(
              children: [
                Checkbox(
                  value: _isCustomReport,
                  onChanged: (bool? newValue) {
                    setState(() {
                      _isCustomReport = newValue!;
                      _selectedReport =
                          null; // Reset selected report when switching to custom
                      _reportController
                          .clear(); // Clear the predefined selection if custom is selected
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

            // Date Picker for selecting the report date
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
