import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'drone_detail_screen.dart';
import 'drone_add_screen.dart';
import 'drone_edit_screen.dart';

class DroneListScreen extends StatefulWidget {
  const DroneListScreen({super.key});

  @override
  _DroneListScreenState createState() => _DroneListScreenState();
}

class _DroneListScreenState extends State<DroneListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _drones = [];

  @override
  void initState() {
    super.initState();
    _loadDrones();
  }

  Future<void> _loadDrones() async {
    final drones = await _dbHelper.getAllDrones1();
    setState(() {
      _drones = drones;
    });
  }

  void _navigateToAddDrone() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DroneFormScreen()),
    );
    if (result == true) {
      _loadDrones();
    }
  }

  void _navigateToEditDrone(Map<String, dynamic> drone) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DroneEditScreen(drone: drone)),
    );
    if (result == true) {
      _loadDrones();
    }
  }

  void _deleteDrone(int droneId) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this drone?'),
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
      await _dbHelper.deleteDrone(droneId);
      _loadDrones();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Drones')),
      body: _drones.isEmpty
          ? const Center(child: Text('No drones found.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _drones.length,
                    itemBuilder: (context, index) {
                      final drone = _drones[index];
                      return Slidable(
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) =>
                                  _navigateToEditDrone(drone),
                              backgroundColor: Colors.blue,
                              icon: Icons.edit,
                              label: 'Edit',
                            ),
                            SlidableAction(
                              onPressed: (context) =>
                                  _deleteDrone(drone['id']),
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
                              onPressed: (context) =>
                                  _navigateToEditDrone(drone),
                              backgroundColor: Colors.blue,
                              icon: Icons.edit,
                              label: 'Edit',
                            ),
                            SlidableAction(
                              onPressed: (context) =>
                                  _deleteDrone(drone['id']),
                              backgroundColor: Colors.red,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            '(${drone['id']}) - ${drone['name'] ?? 'Unknown'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Frame: ${drone['frame']} - Motors: ${drone['motors']} - Weight: ${drone['weight']}g',
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DroneDetailScreen(drone: drone),
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
                    'Swipe left or right to edit or delete a drone.',
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddDrone,
        tooltip: 'Add Drone',
        child: const Icon(Icons.add),
      ),
    );
  }
}
