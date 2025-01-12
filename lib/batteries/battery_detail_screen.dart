import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'battery_addreport_screen.dart';
import 'battery_addusage_screen.dart';
import '../database_helper.dart';

class BatteryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> battery;

  BatteryDetailScreen({required this.battery});

  @override
  _BatteryDetailScreenState createState() => _BatteryDetailScreenState();
}

class _BatteryDetailScreenState extends State<BatteryDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _usage = [];
  bool _showAllReports = false;
  bool _showAllUsage = false;

  @override
  void initState() {
    super.initState();
    _loadReportsAndUsage();
  }

  // Load the reports and usage for the current battery
  Future<void> _loadReportsAndUsage() async {
    final reports = await _dbHelper.getReports(widget.battery['id'], '1');
    final usage = await _dbHelper.getUsageForItem(widget.battery['id'], '1');
    setState(() {
      _reports = reports;
      _usage = usage;
    });
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    final dateTime = DateTime.tryParse(date);
    if (dateTime == null) return 'Invalid Date';
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  void _navigateToAddReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BatteryAddReportScreen(batteryId: widget.battery['id'])),
    ).then((_) => _loadReportsAndUsage());
  }

  void _navigateToAddUsage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BatteryAddUsageScreen(batteryId: widget.battery['id'])),
    ).then((_) => _loadReportsAndUsage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battery Details')),
      body: SingleChildScrollView( // Make the page scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID and number at the top with bold and bigger font
            Text('(${widget.battery['id']})',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Name/Number: ${widget.battery['number'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Type and Capacity next to each other
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Type: ${widget.battery['type'] ?? 'Unknown'}',
                    style: const TextStyle(fontSize: 16)),
                Text('Capacity: ${widget.battery['capacity'] ?? 'N/A'} mAh',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),

            // Storage Watt and Full Watt next to each other
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Storage Watt: ${widget.battery['storage_watt'] ?? 'N/A'} W',
                    style: const TextStyle(fontSize: 16)),
                Text('Full Watt: ${widget.battery['full_watt'] ?? 'N/A'} W',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),

            // Buy Date and End Date next to each other
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.battery['buy_date'] != null || widget.battery['buy_date'].isEmpty)
                  Text('Buy Date: ${_formatDate(widget.battery['buy_date'])}',
                      style: const TextStyle(fontSize: 16)),
                if (widget.battery['end_date'] != null || widget.battery['end_date'].isEmpty)
                  Text('End Date: ${_formatDate(widget.battery['end_date'])}',
                      style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),

            // Buttons for adding report and usage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _navigateToAddUsage(context),
                  child: const Text('Add cycle'),
                ),
                ElevatedButton(
                  onPressed: () => _navigateToAddReport(context),
                  child: const Text('Add Report'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Display reports for this battery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Battery issues/reports:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_reports.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllReports = !_showAllReports;
                      });
                    },
                    child: Text(_showAllReports ? 'Show Less' : 'Show All'),
                  ),
              ],
            ),
            if (_reports.isEmpty)
              const Text('No reports available.')
            else
              ..._reports.take(_showAllReports ? _reports.length : 3).map((report) {
                return ListTile(
                  title: Text(report['report_text']),
                  subtitle: Text('Date: ${_formatDate(report['report_date'])}'),
                );
              }).toList(),

            const SizedBox(height: 16),

            // Display usage for this battery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Battery cycles:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_usage.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllUsage = !_showAllUsage;
                      });
                    },
                    child: Text(_showAllUsage ? 'Show Less' : 'Show All'),
                  ),
              ],
            ),
            if (_usage.isEmpty)
              const Text('No cycles records available.')
            else
              ..._usage.take(_showAllUsage ? _usage.length : 3).map((usage) {
                return ListTile(
                  title: Text('cycle Count: ${usage['usage_count']}'),
                  subtitle: Text('Date: ${_formatDate(usage['usage_date'])}'),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}
