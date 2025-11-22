import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, int> _settings = {
    'batteries_enabled': 0,
    'drones_enabled': 0,
    'inventory_enabled': 0,
  };
  
  int _batteryCount = 0;
  int _droneCount = 0;
  int _inventoryCount = 0;
  int _totalUsageCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final settings = await _dbHelper.getSettings();
    final batteries = await _dbHelper.getAllBatteries();
    final drones = await _dbHelper.getAllDrones();
    final inventory = await _dbHelper.getAllInventoryItems();
    final usage = await _dbHelper.getAllUsage();
    
    int totalUsage = 0;
    for (var entry in usage) {
      totalUsage += entry['usage_count'] as int? ?? 0;
    }

    setState(() {
      _settings = settings;
      _batteryCount = batteries.length;
      _droneCount = drones.length;
      _inventoryCount = inventory.length;
      _totalUsageCount = totalUsage;
      _isLoading = false;
    });
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    ).then((_) => _loadData()); // Reload data when returning from settings
  }

  Widget _buildStatsGrid() {
    List<Widget> statCards = [];
    
    if (_settings['batteries_enabled'] == 1) {
      statCards.add(_StatCard(
        icon: Icons.battery_full,
        title: 'Batteries',
        value: _batteryCount.toString(),
        color: Colors.green,
      ));
    }
    
    if (_settings['drones_enabled'] == 1) {
      statCards.add(_StatCard(
        icon: Icons.flight,
        title: 'Drones',
        value: _droneCount.toString(),
        color: Colors.blue,
      ));
    }
    
    if (_settings['inventory_enabled'] == 1) {
      statCards.add(_StatCard(
        icon: Icons.inventory_2,
        title: 'Inventory',
        value: _inventoryCount.toString(),
        color: Colors.orange,
      ));
    }
    
    // Add Total Cycles if batteries are enabled
    if (_settings['batteries_enabled'] == 1) {
      statCards.add(_StatCard(
        icon: Icons.flight_takeoff,
        title: 'Total Cycles',
        value: _totalUsageCount.toString(),
        color: Colors.purple,
      ));
    }
    
    // Organize into rows of 2
    List<Widget> rows = [];
    for (int i = 0; i < statCards.length; i += 2) {
      if (i + 1 < statCards.length) {
        rows.add(
          Row(
            children: [
              Expanded(child: statCards[i]),
              const SizedBox(width: 12),
              Expanded(child: statCards[i + 1]),
            ],
          ),
        );
        if (i + 2 < statCards.length) {
          rows.add(const SizedBox(height: 12));
        }
      } else {
        rows.add(statCards[i]);
      }
    }
    
    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header Section with Gradient
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'The Drone Logbook',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Track your fleet & batteries',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: _navigateToSettings,
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                tooltip: 'Settings',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Stats Cards
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_settings['batteries_enabled'] == 1 ||
                              _settings['drones_enabled'] == 1 ||
                              _settings['inventory_enabled'] == 1)
                            _buildStatsGrid()
                          else
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.settings_outlined,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No features enabled',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Go to Settings to enable features',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _navigateToSettings,
                                      icon: const Icon(Icons.settings),
                                      label: const Text('Open Settings'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

