import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'battery_addresistance_screen.dart';
import 'battery_addreport_screen.dart';
import 'battery_addusage_screen.dart';
import '../database_helper.dart';

class BatteryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> battery;

  const BatteryDetailScreen({super.key, required this.battery});

  @override
  _BatteryDetailScreenState createState() => _BatteryDetailScreenState();
}

class _BatteryDetailScreenState extends State<BatteryDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _usage = [];
  bool _showAllUsage = false;
  bool _showAllResistance = false;
  bool _showAllReports = false;

  bool get _isNotWrittenOff =>
      widget.battery['end_date'] == null || widget.battery['end_date'].isEmpty;

  @override
  void initState() {
    super.initState();
    _loadReportsResistanceUsage();
    print(_isNotWrittenOff);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> _resistances = [];

  Future<void> _loadReportsResistanceUsage() async {
    final reports = await _dbHelper.getReportsForBattery(widget.battery['id']);
    final usage = await _dbHelper.getUsageForBattery(widget.battery['id']);
    final resistances =
        await _dbHelper.getResistancesForBattery(widget.battery['id']);
    setState(() {
      _reports = reports;
      _usage = usage;
      _resistances = resistances;
    });
  }

  Future<void> _writeOffBattery() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Write Off this Battery'),
          content: const Text(
              'You can write off batteries if they are not usable anymore or if you lost them.\n\n Are you sure you want to write off this battery?\n If you write off a battery you can\'t edit the battery anymore.'),
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
      final currentDate = DateTime.now();

      await _dbHelper.updateBatteryEndDate(widget.battery['id'], currentDate);
      await _loadReportsResistanceUsage();

      _showSnackbar('Battery has been written off successfully!');
      Navigator.pop(context, true);
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
            BatteryAddReportScreen(batteryId: widget.battery['id']),
      ),
    ).then((_) {
      _loadReportsResistanceUsage();
      _showSnackbar('Report added successfully!');
    });
  }

  void _navigateToAddResistance(BuildContext context) {
    final cellCount = widget.battery['cell_count'] ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddResistanceScreen(
          batteryId: widget.battery['id'],
          cellCount: cellCount,
        ),
      ),
    ).then((_) {
      _loadReportsResistanceUsage();
      _showSnackbar('Resistance added successfully!');
    });
  }

  void _navigateToAddUsage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BatteryAddUsageScreen(batteryId: widget.battery['id']),
      ),
    ).then((_) {
      _loadReportsResistanceUsage();
      _showSnackbar('cycle/Usage added successfully!');
    });
  }

  Future<void> _confirmAndDelete(BuildContext context, String message,
      Future<void> Function() onConfirm) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      await onConfirm();
    }
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
            const Divider(),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 400) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name/Number: ${widget.battery['number'] ?? 'Unknown'}',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total cycles: ${widget.battery['total_usage_count'] ?? 0}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Name/Number: ${widget.battery['number'] ?? 'Unknown'}',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total cycles: ${widget.battery['total_usage_count'] ?? 0}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }
              },
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
                Flexible(
                  flex: 1,
                  child: Text(
                    'Brand: ${widget.battery['brand'] ?? '/'}',
                    style: const TextStyle(fontSize: 16),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: Text(
                    'Description: ${widget.battery['description'] ?? '/'}',
                    style: const TextStyle(fontSize: 16),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
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
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // Conditionally Render Buttons
            if (_isNotWrittenOff)
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isSmallScreen = constraints.maxWidth < 400;
                  return isSmallScreen
                      ? Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            ElevatedButton(
                              onPressed: () => _navigateToAddReport(context),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black),
                              child: const Text('Add Report'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  _navigateToAddResistance(context),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black),
                              child: const Text('Add Resistance'),
                            ),
                            ElevatedButton(
                              onPressed: () => _navigateToAddUsage(context),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black),
                              child: const Text('Add Cycle'),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () => _navigateToAddReport(context),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black),
                              child: const Text('Add Report'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  _navigateToAddResistance(context),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black),
                              child: const Text('Add Resistance'),
                            ),
                            ElevatedButton(
                              onPressed: () => _navigateToAddUsage(context),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black),
                              child: const Text('Add Cycle'),
                            ),
                          ],
                        );
                },
              )
            else
              const Text(
                'This battery has been written off.',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            const SizedBox(height: 16),

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
              ..._usage.take(_showAllUsage ? _usage.length : 2).map((usage) {
                return Slidable(
                  startActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: _isNotWrittenOff
                            ? (context) {
                                _confirmAndDelete(
                                  context,
                                  'Are you sure you want to delete this usage record?',
                                  () async {
                                    await _dbHelper.deleteUsage(usage['id']);
                                    await _loadReportsResistanceUsage();
                                    _showSnackbar(
                                        'Usage deleted successfully!');
                                  },
                                );
                              }
                            : null,
                        backgroundColor: Colors.red,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: _isNotWrittenOff
                            ? (context) {
                                _confirmAndDelete(
                                  context,
                                  'Are you sure you want to delete this usage record?',
                                  () async {
                                    await _dbHelper.deleteUsage(usage['id']);
                                    await _loadReportsResistanceUsage();
                                    _showSnackbar(
                                        'Usage deleted successfully!');
                                  },
                                );
                              }
                            : null,
                        backgroundColor: Colors.red,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text('Cycle Count: ${usage['usage_count']}'),
                    subtitle: Text('Date: ${_formatDate(usage['usage_date'])}'),
                  ),
                );
              }),

            const Divider(),

            // Resistances Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Battery resistances:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_resistances.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllResistance = !_showAllResistance;
                      });
                    },
                    child: Text(_showAllResistance ? 'Show Less' : 'Show All'),
                  ),
              ],
            ),
            if (_resistances.isEmpty)
              const Text('No resistances records available.')
            else
              ..._resistances
                  .take(_showAllResistance ? _resistances.length : 2)
                  .map(
                (resistance) {
                  return Slidable(
                    startActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed: _isNotWrittenOff
                              ? (context) {
                                  _confirmAndDelete(
                                    context,
                                    'Are you sure you want to delete this resistance record?',
                                    () async {
                                      await _dbHelper
                                          .deleteResistance(resistance['id']);
                                      await _loadReportsResistanceUsage();
                                      _showSnackbar(
                                          'Resistance deleted successfully!');
                                    },
                                  );
                                }
                              : null,
                          backgroundColor: Colors.red,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed: _isNotWrittenOff
                              ? (context) {
                                  _confirmAndDelete(
                                    context,
                                    'Are you sure you want to delete this resistance record?',
                                    () async {
                                      await _dbHelper
                                          .deleteResistance(resistance['id']);
                                      await _loadReportsResistanceUsage();
                                      _showSnackbar(
                                          'Resistance deleted successfully!');
                                    },
                                  );
                                }
                              : null,
                          backgroundColor: Colors.red,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 16.0,
                            runSpacing: 8.0,
                            children: [
                              for (int i = 1;
                                  i <= widget.battery['cell_count'];
                                  i++)
                                if (resistance['resistance_c$i'] != null)
                                  Text(
                                    'C$i: ${resistance['resistance_c$i']} mΩ',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                            ],
                          ),
                          Text(
                            'Date: ${_formatDate(resistance['date'])}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const Divider(),

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
                  .take(_showAllReports ? _reports.length : 2)
                  .map((report) {
                final bool isResolved = report['resolved'] == 1;

                return Slidable(
                  startActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: _isNotWrittenOff
                            ? (context) {
                                _confirmAndDelete(
                                  context,
                                  'Are you sure you want to delete this report?',
                                  () async {
                                    await _dbHelper.deleteReport(report['id']);
                                    await _loadReportsResistanceUsage();
                                    _showSnackbar(
                                        'Report deleted successfully!');
                                  },
                                );
                              }
                            : null,
                        backgroundColor: Colors.red,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                      if (!isResolved)
                        SlidableAction(
                          onPressed: _isNotWrittenOff
                              ? (context) {
                                  _confirmAndDelete(
                                    context,
                                    'Are you sure you want to mark this report as resolved/fixed?',
                                    () async {
                                      await _dbHelper.fixReport(report['id']);
                                      await _loadReportsResistanceUsage();
                                      _showSnackbar(
                                          'Report marked as resolved/fixed successfully!');
                                    },
                                  );
                                }
                              : null,
                          backgroundColor: Colors.yellow,
                          icon: Icons.miscellaneous_services,
                          label: 'Resolve',
                        ),
                    ],
                  ),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: _isNotWrittenOff
                            ? (context) {
                                _confirmAndDelete(
                                  context,
                                  'Are you sure you want to delete this report?',
                                  () async {
                                    await _dbHelper.deleteReport(report['id']);
                                    await _loadReportsResistanceUsage();
                                    _showSnackbar(
                                        'Report deleted successfully!');
                                  },
                                );
                              }
                            : null,
                        backgroundColor: Colors.red,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                      if (!isResolved)
                        SlidableAction(
                          onPressed: _isNotWrittenOff
                              ? (context) {
                                  _confirmAndDelete(
                                    context,
                                    'Are you sure you want to mark this report as resolved/fixed?',
                                    () async {
                                      await _dbHelper.fixReport(report['id']);
                                      await _loadReportsResistanceUsage();
                                      _showSnackbar(
                                          'Report marked as resolved/fixed successfully!');
                                    },
                                  );
                                }
                              : null,
                          backgroundColor: Colors.yellow,
                          icon: Icons.miscellaneous_services,
                          label: 'Resolve',
                        ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(report['report_text']),
                    subtitle:
                        Text('Date: ${_formatDate(report['report_date'])}'),
                    trailing: isResolved
                        ? const Icon(Icons.check_outlined, color: Colors.green)
                        : null,
                  ),
                );
              }),

            const Divider(),

            const SizedBox(height: 8),
            if (_isNotWrittenOff)
              const Text(
                'Swipe left or right to perform actions like deleting on the cycles, resistance or reports.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
