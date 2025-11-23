// ignore_for_file: avoid_print

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'battery_editusage_screen.dart';
import 'battery_addresistance_screen.dart';
import 'battery_addreport_screen.dart';
import 'battery_addusage_screen.dart';
import '../database_helper.dart';
import 'battery_barcode_view_screen.dart';

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

  // Write off methods commented out - needs app reload to take effect properly
  // Future<void> _writeOffBattery() async {
  //   final confirmation = await showDialog<bool>(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text('Write Off this Battery'),
  //         content: const Text(
  //             'You can write off batteries if they are not usable anymore or if you lost them.\n\n Are you sure you want to write off this battery?\n If you write off a battery you can\'t edit the battery anymore.'),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(false),
  //             child: const Text('Cancel'),
  //           ),
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(true),
  //             child: const Text('Confirm'),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   if (confirmation == true) {
  //     final currentDate = DateTime.now();

  //     await _dbHelper.updateBatteryEndDate(widget.battery['id'], currentDate);
  //     await _loadReportsResistanceUsage();

  //     _showSnackbar('Battery has been written off successfully!');
  //     Navigator.pop(context, true);
  //   }
  // }

  // Future<void> _unwriteOffBattery() async {
  //   final confirmation = await showDialog<bool>(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text('Unwrite Off this Battery'),
  //         content: const Text(
  //             'Are you sure you want to unwrite off this battery?\n\nThis will allow you to edit the battery again.'),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(false),
  //             child: const Text('Cancel'),
  //           ),
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(true),
  //             child: const Text('Confirm'),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   if (confirmation == true) {
  //     await _dbHelper.updateBatteryEndDate(widget.battery['id'], null);
  //     await _loadReportsResistanceUsage();

  //     _showSnackbar('Battery has been unwritten off successfully!');
  //     Navigator.pop(context, true);
  //   }
  // }

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

  void _viewBarcode() {
    final barcodeId = widget.battery['barcode_id']?.toString();
    if (barcodeId == null || barcodeId.isEmpty) {
      _showSnackbar('No barcode assigned to this battery yet.');
      return;
    }
    final title =
        widget.battery['number']?.toString() ?? 'Battery ${widget.battery['id']}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatteryBarcodeViewScreen(
          barcodeId: barcodeId,
          title: title,
        ),
      ),
    );
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
      appBar: AppBar(
        title: const Text('Battery Details'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isNotWrittenOff
                                ? Colors.green.shade50
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.battery_full,
                            color: _isNotWrittenOff
                                ? Colors.green
                                : Colors.grey,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Battery #${widget.battery['id']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.battery['number'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Write off button commented out - needs app reload to take effect
                    // if (_isNotWrittenOff)
                    //   ElevatedButton.icon(
                    //     onPressed: _writeOffBattery,
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.red.shade50,
                    //       foregroundColor: Colors.red.shade700,
                    //       elevation: 0,
                    //     ),
                    //     icon: const Icon(Icons.block, size: 18),
                    //     label: const Text('Write Off'),
                    //   )
                    // else
                    //   ElevatedButton.icon(
                    //     onPressed: _unwriteOffBattery,
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.green.shade50,
                    //       foregroundColor: Colors.green.shade700,
                    //       elevation: 0,
                    //     ),
                    //     icon: const Icon(Icons.restore, size: 18),
                    //     label: const Text('Unwrite Off'),
                    //   ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Compact battery info
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: 'Type',
                  value: widget.battery['type'] ?? 'Unknown',
                ),
                _InfoChip(
                  label: 'Capacity',
                  value: '${widget.battery['capacity'] ?? 'unknown'} mAh',
                ),
                _InfoChip(
                  label: 'Cells',
                  value: '${widget.battery['cell_count'] ?? 'unknown'}s',
                ),
                _InfoChip(
                  label: 'Cycles',
                  value: '${widget.battery['total_usage_count'] ?? 0}',
                ),
                if (widget.battery['buy_date'] != null &&
                    widget.battery['buy_date'].toString().isNotEmpty)
                  _InfoChip(
                    label: 'Bought',
                    value: _formatDate(widget.battery['buy_date']),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _viewBarcode,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('View Barcode'),
            ),
            const SizedBox(height: 12),

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
                ],
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Cycles'),
              Tab(text: 'Resistances'),
              Tab(text: 'Reports'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Usage Section
                _usage.isEmpty
                    ? const Center(child: Text('No cycles records available.'))
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: _usage.length,
                              itemBuilder: (context, index) {
                          final usage = _usage[index];
                          return Slidable(
                            startActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BatteryEditUsageScreen(
                                          usageId: usage['id'],
                                          onUsageUpdated:
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
                                        builder: (context) =>
                                            BatteryEditUsageScreen(
                                          usageId: usage['id'],
                                          onUsageUpdated:
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
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.flight_takeoff,
                                    color: Colors.blue.shade700,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  '${usage['usage_count']} cycle${usage['usage_count'] == 1 ? '' : 's'} • ${usage['flight_time_minutes']} min',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _formatDate(usage['usage_date']),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Text(
                              'Swipe left or right on an item to edit or delete.',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                  // Resistances Section
                  _resistances.isEmpty
                      ? const Center(child: Text('No resistances records available.'))
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: _resistances.length,
                                itemBuilder: (context, index) {
                            final resistance = _resistances[index];
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
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.electrical_services,
                                              color: Colors.orange.shade700,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Wrap(
                                              spacing: 12.0,
                                              runSpacing: 8.0,
                                              children: [
                                                for (int i = 1;
                                                    i <= widget.battery['cell_count'];
                                                    i++)
                                                  if (resistance['resistance_c$i'] !=
                                                      null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade100,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        'C$i: ${resistance['resistance_c$i']}mΩ',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatDate(resistance['date']),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Text(
                                'Swipe left or right on an item to delete.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                  // Reports Section
                  _reports.isEmpty
                      ? const Center(child: Text('No reports available.'))
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: _reports.length,
                                itemBuilder: (context, index) {
                            final report = _reports[index];
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
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isResolved
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isResolved
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    color: isResolved
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  report['report_text'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    decoration: isResolved
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isResolved
                                        ? Colors.grey.shade600
                                        : null,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _formatDate(report['report_date']),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                trailing: isResolved
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Resolved',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Text(
                                'Swipe left or right on an item to edit, delete, or resolve.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade800,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
