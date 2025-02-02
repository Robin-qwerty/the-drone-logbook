import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'drone_editusage_screen.dart';
import 'drone_addreport_screen.dart';
import 'drone_addusage_screen.dart';
import '../database_helper.dart';

class DroneDetailScreen extends StatefulWidget {
  final Map<String, dynamic> drone;

  const DroneDetailScreen({super.key, required this.drone});

  @override
  _DroneDetailScreenState createState() => _DroneDetailScreenState();
}

class _DroneDetailScreenState extends State<DroneDetailScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _maintenanceReports = [];
  List<Map<String, dynamic>> _flightLogs = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDroneData();
  }

  void _loadDroneData() async {
    var flightLogs = await _dbHelper.getFlightLogsForDrone(widget.drone['id']);
    var reports = await _dbHelper.getReportsForDrone(widget.drone['id']);

    setState(() {
      _flightLogs = flightLogs;
      _maintenanceReports = reports;
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
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
        builder: (context) => DroneAddReportScreen(droneId: widget.drone['id']),
      ),
    ).then((results) {
      _loadDroneData();
      if (results == true) {
        _showSnackbar('report added successfully!');
      }
    });
  }

  void _navigateToAddFlightLog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DroneAddFlightLogScreen(droneId: widget.drone['id']),
      ),
    ).then((results) {
      _loadDroneData();
      if (results == true) {
        _showSnackbar('Flight log added successfully!');
      }
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

  Future<void> _deleteFlightLog(int id) async {
    await _dbHelper.deleteFlightLog(id);
    _loadDroneData();
    _showSnackbar('Flight log deleted successfully!');
  }

  Future<void> _deleteReport(int id) async {
    await _dbHelper.deleteReport(id);
    _loadDroneData();
    _showSnackbar('Report deleted successfully!');
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
    final reports = await _dbHelper.getReportsForDrone(widget.drone['id']);
    setState(() {
      _maintenanceReports = reports;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drone Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '(${widget.drone['id']}) ${widget.drone['name'] ?? 'Unknown'}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total flights: ${widget.drone['total_flight_count'] ?? 0}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            RichText(
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
                    text: widget.drone['description'] ??
                        'No description available',
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.spaceBetween,
              children: [
                if (widget.drone['frame'] != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Frame: ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${widget.drone['frame']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (widget.drone['esc'] != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'ESC: ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${widget.drone['esc']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (widget.drone['fc'] != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'FC: ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${widget.drone['fc']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (widget.drone['vtx'] != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'VTX: ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${widget.drone['vtx']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (widget.drone['antenna'] != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Antenna: ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${widget.drone['antenna']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (widget.drone['receiver'] != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Receiver: ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${widget.drone['receiver']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (widget.drone['motors'] != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Motors: ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${widget.drone['motors']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (widget.drone['camera'] != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Camera: ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${widget.drone['camera']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (widget.drone['props'] != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Props: ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${widget.drone['props']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (widget.drone['buzzer'] != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Buzzer: ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${widget.drone['buzzer']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (widget.drone['weight'] != null)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'weight: ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${widget.drone['weight']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => _navigateToAddFlightLog(context),
                      style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black),
                      child: const Text('Add flight'),
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
            ),
            const SizedBox(height: 16),
            const Divider(),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Flight Logs'),
                Tab(text: 'Reports'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 500,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Flight Logs Tab
                  Column(
                    children: [
                      if (_flightLogs.isEmpty)
                        const Text('No flight logs available.')
                      else
                        ..._flightLogs.map((log) {
                          return Slidable(
                            key: ValueKey(log['id']),
                            startActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditFlightLogScreen(
                                          logId: log['id'],
                                          onLogUpdated: _loadDroneData,
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
                                  onPressed: (context) => _confirmAndDelete(
                                    context,
                                    'Are you sure you want to delete this flight log?',
                                    () => _deleteFlightLog(log['id']),
                                  ),
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
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
                                            EditFlightLogScreen(
                                          logId: log['id'],
                                          onLogUpdated: _loadDroneData,
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
                                  onPressed: (context) => _confirmAndDelete(
                                    context,
                                    'Are you sure you want to delete this flight log?',
                                    () => _deleteFlightLog(log['id']),
                                  ),
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                  'flown ${log['usage_count']} times with a total flight time of ${log['flight_time_minutes']} minutes'),
                              subtitle: Text(
                                'Date: ${_formatDate(log['usage_date'])}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),

                  // Maintenance Reports Tab
                  Column(
                    children: [
                      if (_maintenanceReports.isEmpty)
                        const Text('No reports available.')
                      else
                        ..._maintenanceReports.map((report) {
                          final bool isResolved = report['resolved'] == 1;

                          return Slidable(
                            key: ValueKey(report['id']),
                            startActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) => _confirmAndDelete(
                                    context,
                                    'Are you sure you want to delete this report?',
                                    () => _deleteReport(report['id']),
                                  ),
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
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
                                  onPressed: (context) => _confirmAndDelete(
                                    context,
                                    'Are you sure you want to delete this report?',
                                    () => _deleteReport(report['id']),
                                  ),
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
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
                                  'Date: ${_formatDate(report['report_date'])}'),
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
