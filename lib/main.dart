import 'package:flutter/material.dart';
import 'batteries/battery_list_screen.dart';
import 'database_helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battery Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Widget> _screens = [];
  List<BottomNavigationBarItem> _bottomNavItems = [];

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    _dumpDatabase();
  }

  Future<void> _initializeSettings() async {
    final settings = await _dbHelper.getSettings();
    print('Loaded settings: $settings');

    setState(() {
      _screens = [
        HomeScreen(),
        if (settings['batteries_enabled'] == 1) BatteryListScreen(),
        if (settings['drones_enabled'] == 1) DronesScreen(),
        if (settings['expenses_enabled'] == 1) DroneShoppingScreen(),
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
        if (settings['expenses_enabled'] == 0)
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Shopping',
          ),
      ];
    });
  }

  Future<void> _dumpDatabase() async {
    final batteries = await _dbHelper.getAllBatteries();
    final reports = await _dbHelper.getAllReports();
    final usage = await _dbHelper.getAllUsage();
    final expenses = await _dbHelper.getAllExpenses();
    final drones = await _dbHelper.getAllDrones();
    final settings = await _dbHelper.getAllSettings();

    print('Batteries:');
    batteries.forEach((battery) => print(battery));

    print('\nReports:');
    reports.forEach((report) => print(report));

    print('\nUsage:');
    usage.forEach((entry) => print(entry));

    print('\nExpenses:');
    expenses.forEach((entry) => print(entry));

    print('\nDrones:');
    drones.forEach((entry) => print(entry));

    print('\nSettings:');
    settings.forEach((entry) => print(entry));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The drone logbook'),
      ),
      body: _screens.isNotEmpty
          ? _screens[_selectedIndex]
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: BottomNavigationBar(
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

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Welcome to the Home Screen!',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class DronesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Drones Screen',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class DroneShoppingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Drone Shopping Screen',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text('Settings Page (to be implemented)'),
      ),
    );
  }
}
