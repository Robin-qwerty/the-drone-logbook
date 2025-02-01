import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'battery_detail_screen.dart';
import 'battery_addbattery_screen.dart';
import 'battery_edit_screen.dart';

class BatteryListScreen extends StatefulWidget {
  const BatteryListScreen({super.key});

  @override
  _BatteryListScreenState createState() => _BatteryListScreenState();
}

class _BatteryListScreenState extends State<BatteryListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _batteries = [];

  @override
  void initState() {
    super.initState();
    _loadBatteries();
  }

  Future<void> _loadBatteries() async {
    final batteries = await _dbHelper.getAllBatteries();
    setState(() {
      _batteries = batteries;
    });
  }

  void _navigateToAddBattery() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BatteryFormScreen()),
    );
    if (result == true) {
      _loadBatteries();
    }
  }

  void _navigateToEditBattery(Map<String, dynamic> battery) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => BatteryEditScreen(battery: battery)),
    );
    if (result == true) {
      _loadBatteries();
    }
  }

  void _deleteBattery(int batteryId) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this battery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteBattery(batteryId);
      _loadBatteries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your batteries')),
      body: _batteries.isEmpty
          ? const Center(child: Text('No batteries found.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _batteries.length,
                    itemBuilder: (context, index) {
                      final battery = _batteries[index];
                      return Slidable(
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            if (battery['end_date'] == null ||
                                battery['end_date'].isEmpty)
                              SlidableAction(
                                onPressed: (context) =>
                                    _navigateToEditBattery(battery),
                                backgroundColor: Colors.blue,
                                icon: Icons.edit,
                                label: 'Edit',
                              ),
                            SlidableAction(
                              onPressed: (context) =>
                                  _deleteBattery(battery['id']),
                              backgroundColor: Colors.red,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            if (battery['end_date'] == null ||
                                battery['end_date'].isEmpty)
                              SlidableAction(
                                onPressed: (context) =>
                                    _navigateToEditBattery(battery),
                                backgroundColor: Colors.blue,
                                icon: Icons.edit,
                                label: 'Edit',
                              ),
                            SlidableAction(
                              onPressed: (context) =>
                                  _deleteBattery(battery['id']),
                              backgroundColor: Colors.red,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            '(${battery['id']}) - ${battery['number'] ?? 'Unknown'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Type: ${battery['type']} - Capacity: ${battery['capacity']} mAh - total cycles: ${battery['total_usage_count']}',
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BatteryDetailScreen(battery: battery),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Swipe left or right to edit or delete a battery.',
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddBattery,
        tooltip: 'Add Battery',
        child: const Icon(Icons.add),
      ),
    );
  }
}
