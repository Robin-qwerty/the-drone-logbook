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

  bool get _isNotWrittenOff =>
      widget.battery['end_date'] == null ||
      widget.battery['end_date'].isEmpty;

  @override
  void initState() {
    super.initState();
    _loadReportsAndUsage();
    print(_isNotWrittenOff);
  }

  Future<void> _loadReportsAndUsage() async {
    final reports = await _dbHelper.getReports(widget.battery['id']);
    final usage = await _dbHelper.getUsageForItem(widget.battery['id']);
    setState(() {
      _reports = reports;
      _usage = usage;
    });
  }

  Future<void> _writeOffBattery() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Write Off this Battery'),
          content:
              const Text('You can write off batteries if there not usable anymore or if you lost them.\n\n Are you sure you want to write off this battery?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      final currentDate = DateTime.now(); // Get DateTime directly
      await _dbHelper.updateBatteryEndDate(widget.battery['id'], currentDate);
      setState(() {
        widget.battery['end_date'] = currentDate.toIso8601String();
      });
    }
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
      MaterialPageRoute(
          builder: (context) =>
              BatteryAddReportScreen(batteryId: widget.battery['id'])),
    ).then((_) => _loadReportsAndUsage());
  }

  void _navigateToAddUsage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              BatteryAddUsageScreen(batteryId: widget.battery['id'])),
    ).then((_) => _loadReportsAndUsage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battery Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '(${widget.battery['id']})',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (_isNotWrittenOff)
                  ElevatedButton(
                    onPressed: _writeOffBattery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 215, 88, 78),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Write Off'),
                  ),
              ],
            ),
            Text(
              'Name/Number: ${widget.battery['number'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Type: ${widget.battery['type'] ?? 'Unknown'}',
                    style: const TextStyle(fontSize: 16)),
                if (widget.battery['buy_date'] != null ||
                    widget.battery['buy_date'].isEmpty)
                  Text('Bought on: ${_formatDate(widget.battery['buy_date'])}',
                      style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),

            // Other Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Brand: ${widget.battery['brand'] ?? '/'}',
                    style: const TextStyle(fontSize: 16)),
                Text('Description: ${widget.battery['description'] ?? '/'}',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Capacity: ${widget.battery['capacity'] ?? 'unknown'}mAh',
                    style: const TextStyle(fontSize: 16)),
                Text(
                    'Cell count: ${widget.battery['cell_count'] ?? 'unknown'}s',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Full Watt: ${widget.battery['full_watt'] ?? 'unknown'}W',
                    style: const TextStyle(fontSize: 16)),
                Text(
                    'Storage Watt: ${widget.battery['storage_watt'] ?? 'unknown'}W',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),

            // Conditionally Render Buttons
            if (_isNotWrittenOff)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => _navigateToAddReport(context),
                    style:
                        ElevatedButton.styleFrom(foregroundColor: Colors.black),
                    child: const Text('Add Report'),
                  ),
                  ElevatedButton(
                    onPressed: () => _navigateToAddUsage(context),
                    style:
                        ElevatedButton.styleFrom(foregroundColor: Colors.black),
                    child: const Text('Add cycle/usage'),
                  ),
                ],
              )
            else
              const Text(
                'This battery has been written off.',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            const SizedBox(height: 8),

            // Reports Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Battery issues/reports:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              ..._reports
                  .take(_showAllReports ? _reports.length : 3)
                  .map((report) {
                return ListTile(
                  title: Text(report['report_text']),
                  subtitle: Text('Date: ${_formatDate(report['report_date'])}'),
                );
              }),

            const SizedBox(height: 8),

            // Usage Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Battery cycles:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  title: Text('Cycle Count: ${usage['usage_count']}'),
                  subtitle: Text('Date: ${_formatDate(usage['usage_date'])}'),
                );
              }),
          ],
        ),
      ),
    );
  }
}
