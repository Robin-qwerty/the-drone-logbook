// ignore_for_file: avoid_print

import 'batteries/battery_list_screen.dart';
import 'drones/drone_list_screen.dart';
import 'inventory/inventory_list_screen.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battery Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, int> _settings = {
    'batteries_enabled': 0,
    'drones_enabled': 0,
    'inventory_enabled': 0,
  };

  List<Widget> _screens = [];
  List<BottomNavigationBarItem> _bottomNavItems = [];

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    _loadSettings();
    _dumpDatabase();
  }

  Future<void> _loadSettings() async {
    final settings = await _dbHelper.getSettings();
    setState(() {
      _settings = settings;
    });
  }

  Future<void> _dumpDatabase() async {
    final batteries = await _dbHelper.getAllBatteries();
    final batteryResistance = await _dbHelper.getAllResistances();
    final reports = await _dbHelper.getAllReports();
    final usage = await _dbHelper.getAllUsage();
    final inventory = await _dbHelper.getAllInventory();
    final drones = await _dbHelper.getAllDrones();
    final settings = await _dbHelper.getAllSettings();

    print('Batteries:');
    for (var battery in batteries) {
      print(battery);
    }

    print('\nbattery_resistance:');
    for (var battery_resistance in batteryResistance) {
      print(battery_resistance);
    }

    print('\nReports:');
    for (var report in reports) {
      print(report);
    }

    print('\nUsage:');
    for (var entry in usage) {
      print(entry);
    }

    print('\nInventory:');
    for (var entry in inventory) {
      print(entry);
    }

    print('\nDrones:');
    for (var entry in drones) {
      print(entry);
    }

    print('\nSettings:');
    for (var entry in settings) {
      print(entry);
    }
  }

  Future<void> _initializeSettings() async {
    final settings = await _dbHelper.getSettings();

    setState(() {
      _screens = [
        const HomeScreen(),
        if (settings['batteries_enabled'] == 1) const BatteryListScreen(),
        if (settings['drones_enabled'] == 1) const DroneListScreen(),
        if (settings['inventory_enabled'] == 1) const InventoryListScreen(),
      ];

      _bottomNavItems = [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        if (settings['batteries_enabled'] == 1)
          const BottomNavigationBarItem(
            icon: Icon(Icons.battery_full),
            label: 'Batteries',
          ),
        if (settings['drones_enabled'] == 1)
          const BottomNavigationBarItem(
            icon: Icon(Icons.flight),
            label: 'Drones',
          ),
        if (settings['inventory_enabled'] == 1)
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
      ];
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool allSettingsDisabled = _settings.values.every((value) => value == 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Drone Logbook'),
      ),
      body: allSettingsDisabled
          ? const HomeScreen()
          : (_screens.isNotEmpty
              ? _screens[_selectedIndex]
              : const Center(child: CircularProgressIndicator())),
      bottomNavigationBar: allSettingsDisabled
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: _bottomNavItems.isNotEmpty
                  ? _bottomNavItems
                  : [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.settings),
                        label: 'Settings',
                      ),
                    ],
            ),
    );
  }
}