import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'battery_detail_screen.dart';
import 'battery_add_screen.dart';
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
      MaterialPageRoute(builder: (context) => const BatteryFormScreen()),
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
      appBar: AppBar(
        title: const Text('Your Batteries'),
        elevation: 0,
      ),
      body: _batteries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.battery_unknown,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No batteries found.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _batteries.length,
                    itemBuilder: (context, index) {
                      final battery = _batteries[index];
                      final isWrittenOff = battery['end_date'] != null &&
                          battery['end_date'].toString().isNotEmpty;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Slidable(
                          startActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: [
                              if (!isWrittenOff)
                                SlidableAction(
                                  onPressed: (context) =>
                                      _navigateToEditBattery(battery),
                                  backgroundColor: Colors.blue,
                                  icon: Icons.edit,
                                  label: 'Edit',
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                              SlidableAction(
                                onPressed: (context) =>
                                    _deleteBattery(battery['id']),
                                backgroundColor: Colors.red,
                                icon: Icons.delete,
                                label: 'Delete',
                                borderRadius: !isWrittenOff
                                    ? BorderRadius.zero
                                    : const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                              ),
                            ],
                          ),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: [
                              if (!isWrittenOff)
                                SlidableAction(
                                  onPressed: (context) =>
                                      _navigateToEditBattery(battery),
                                  backgroundColor: Colors.blue,
                                  icon: Icons.edit,
                                  label: 'Edit',
                                  borderRadius: BorderRadius.zero,
                                ),
                              SlidableAction(
                                onPressed: (context) =>
                                    _deleteBattery(battery['id']),
                                backgroundColor: Colors.red,
                                icon: Icons.delete,
                                label: 'Delete',
                                borderRadius: !isWrittenOff
                                    ? const BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      )
                                    : const BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isWrittenOff
                                    ? Colors.grey.shade200
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.battery_full,
                                color: isWrittenOff
                                    ? Colors.grey
                                    : Colors.green,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              '${battery['number'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: isWrittenOff
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isWrittenOff
                                    ? Colors.grey
                                    : null,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${battery['type']} • ${battery['capacity']} mAh • ${battery['cell_count']}s',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${battery['total_usage_count'] ?? 0} cycles',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: isWrittenOff
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Written Off',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BatteryDetailScreen(battery: battery),
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
                    'Swipe left or right to edit or delete a battery.',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddBattery,
        tooltip: 'Add Battery',
        icon: const Icon(Icons.add),
        label: const Text('Add Battery'),
      ),
    );
  }
}
