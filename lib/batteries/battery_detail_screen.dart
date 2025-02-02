// ignore_for_file: avoid_print

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../drones/drone_editusage_screen.dart';
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

class _BatteryDetailScreenState extends State<BatteryDetailScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _usage = [];
  late TabController _tabController;

  bool get _isNotWrittenOff =>
      widget.battery['end_date'] == null || widget.battery['end_date'].isEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

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
    if (dateTime == null) return 'no date set';
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  void _navigateToAddReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BatteryAddReportScreen(batteryId: widget.battery['id']),
      ),
    ).then((results) {
      _loadReportsResistanceUsage();
      if (results == true) {
        _showSnackbar('Report added successfully!');
      }
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
    ).then((results) {
      _loadReportsResistanceUsage();
      if (results == true) {
        _showSnackbar('Resistance added successfully!');
      }
    });
  }

  void _navigateToAddUsage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BatteryAddUsageScreen(batteryId: widget.battery['id']),
      ),
    ).then((results) {
      _loadReportsResistanceUsage();
      if (results == true) {
        _showSnackbar('cycle/Usage added successfully!');
      }
    });
  }

  Future<void> _confirmAndDelete(BuildContext context, String message,
      Future<void> Function() onConfirm) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      await onConfirm();
    }
  }

  Future<bool?> _confirmAction(BuildContext context, String message) async {
    return await showDialog<bool>(
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
  }

  Future<void> _loadMaintenanceReports() async {
    final reports = await _dbHelper.getReportsForBattery(widget.battery['id']);
    setState(() {
      _reports = reports;
    });
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
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Type: ',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      TextSpan(
                        text: widget.battery['type'] ?? 'Unknown',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                if (widget.battery['buy_date'] != null ||
                    widget.battery['buy_date'].isEmpty)
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Bought on: ',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        TextSpan(
                          text: _formatDate(widget.battery['buy_date']),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

// Other Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 1,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Brand: ',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        TextSpan(
                          text: widget.battery['brand'] ?? '/',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Description: ',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        TextSpan(
                          text: widget.battery['description'] ?? '/',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Capacity: ',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      TextSpan(
                        text: '${widget.battery['capacity'] ?? 'unknown'}mAh',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Cell count: ',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      TextSpan(
                        text: '${widget.battery['cell_count'] ?? 'unknown'}s',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Full Watt: ',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      TextSpan(
                        text: '${widget.battery['full_watt'] ?? 'unknown'}W',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Storage Watt: ',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      TextSpan(
                        text: '${widget.battery['storage_watt'] ?? 'unknown'}W',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
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
                              onPressed: () => _navigateToAddUsage(context),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black),
                              child: const Text('Add Cycle'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  _navigateToAddResistance(context),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black),
                              child: const Text('Add Resistance'),
                            ),
                            ElevatedButton(
                              onPressed: () => _navigateToAddReport(context),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black),
                              child: const Text('Add Report'),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () => _navigateToAddUsage(context),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black),
                              child: const Text('Add Cycle'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  _navigateToAddResistance(context),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black),
                              child: const Text('Add Resistance'),
                            ),
                            ElevatedButton(
                              onPressed: () => _navigateToAddReport(context),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black),
                              child: const Text('Add Report'),
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
            const Divider(),

            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Cycles'),
                Tab(text: 'Resistances'),
                Tab(text: 'Reports'),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 500,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Usage Section
                  Column(children: [
                    if (_usage.isEmpty)
                      const Text('No cycles records available.')
                    else
                      ..._usage.map((usage) {
                        return Slidable(
                          startActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditFlightLogScreen(
                                        logId: usage['id'],
                                        onLogUpdated:
                                            _loadReportsResistanceUsage,
                                      ),
                                    ),
                                  );
                                },
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: 'Edit',
                              ),
                              SlidableAction(
                                onPressed: _isNotWrittenOff
                                    ? (context) {
                                        _confirmAndDelete(
                                          context,
                                          'Are you sure you want to delete this usage record?',
                                          () async {
                                            await _dbHelper
                                                .deleteUsage(usage['id']);
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
                                onPressed: (context) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditFlightLogScreen(
                                        logId: usage['id'],
                                        onLogUpdated:
                                            _loadReportsResistanceUsage,
                                      ),
                                    ),
                                  );
                                },
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: 'Edit',
                              ),
                              SlidableAction(
                                onPressed: _isNotWrittenOff
                                    ? (context) {
                                        _confirmAndDelete(
                                          context,
                                          'Are you sure you want to delete this usage record?',
                                          () async {
                                            await _dbHelper
                                                .deleteUsage(usage['id']);
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
                            title: Text(
                                'flown ${usage['usage_count']} times with a total flight time of ${usage['flight_time_minutes']} minutes'),
                            subtitle: Text(
                              'Date: ${_formatDate(usage['usage_date'])}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }),
                  ]),

                  // Resistances Section
                  Column(
                    children: [
                      if (_resistances.isEmpty)
                        const Text('No resistances records available.')
                      else
                        ..._resistances.map(
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
                                                    .deleteResistance(
                                                        resistance['id']);
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
                                                    .deleteResistance(
                                                        resistance['id']);
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
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
                                          if (resistance['resistance_c$i'] !=
                                              null)
                                            Text(
                                              'C$i: ${resistance['resistance_c$i']}mΩ',
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                      ],
                                    ),
                                    Text(
                                      'Date: ${_formatDate(resistance['date'])}',
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),

                  // Reports Section
                  Column(
                    children: [
                      if (_reports.isEmpty)
                        const Text('No reports available.')
                      else
                        ..._reports.map((report) {
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
                                              await _dbHelper
                                                  .deleteReport(report['id']);
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
                                if (report['resolved'] == 0)
                                  SlidableAction(
                                    onPressed: (context) async {
                                      bool? confirm = await _confirmAction(
                                        context,
                                        'Are you sure you want to resolve this report?',
                                      );
                                      if (confirm == true) {
                                        await _dbHelper
                                            .markReportResolved(report['id']);
                                        _loadMaintenanceReports();
                                      }
                                    },
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    icon: Icons.check,
                                    label: 'Resolved',
                                  ),
                                if (report['resolved'] == 1)
                                  SlidableAction(
                                    onPressed: (context) async {
                                      bool? confirm = await _confirmAction(
                                        context,
                                        'Are you sure you want to unresolve this report?',
                                      );
                                      if (confirm == true) {
                                        await _dbHelper
                                            .markReportUnresolved(report['id']);
                                        _loadMaintenanceReports();
                                      }
                                    },
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    icon: Icons.undo,
                                    label: 'Unresolved',
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
                                              await _dbHelper
                                                  .deleteReport(report['id']);
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
                                if (report['resolved'] == 0)
                                  SlidableAction(
                                    onPressed: (context) async {
                                      bool? confirm = await _confirmAction(
                                        context,
                                        'Are you sure you want to resolve this report?',
                                      );
                                      if (confirm == true) {
                                        await _dbHelper
                                            .markReportResolved(report['id']);
                                        _loadMaintenanceReports();
                                      }
                                    },
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    icon: Icons.check,
                                    label: 'Resolved',
                                  ),
                                if (report['resolved'] == 1)
                                  SlidableAction(
                                    onPressed: (context) async {
                                      bool? confirm = await _confirmAction(
                                        context,
                                        'Are you sure you want to unresolve this report?',
                                      );
                                      if (confirm == true) {
                                        await _dbHelper
                                            .markReportUnresolved(report['id']);
                                        _loadMaintenanceReports();
                                      }
                                    },
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    icon: Icons.undo,
                                    label: 'Unresolved',
                                  ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(report['report_text']),
                              subtitle: Text(
                                'Date: ${_formatDate(report['report_date'])}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: isResolved
                                  ? const Icon(Icons.check_outlined,
                                      color: Colors.green)
                                  : null,
                            ),
                          );
                        }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
