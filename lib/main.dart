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

  Future<void> _dumpDatabase() async {
    final batteries = await _dbHelper.getAllBatteries();
    final batteryResistance = await _dbHelper.getAllBatteryResistances();
    final reports = await _dbHelper.getAllReports();
    final usage = await _dbHelper.getAllUsage();
    final expenses = await _dbHelper.getAllExpenses();
    final drones = await _dbHelper.getAllDrones();
    final settings = await _dbHelper.getAllSettings();

    print('Batteries:');
    batteries.forEach((battery) => print(battery));

    print('\nbattery_resistance:');
    batteryResistance.forEach((battery_resistance) => print(battery_resistance));

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

  Future<void> _initializeSettings() async {
    final settings = await _dbHelper.getSettings();

    setState(() {
      _screens = [
        HomeScreen(),
        if (settings['batteries_enabled'] == 1) BatteryListScreen(),
        if (settings['drones_enabled'] == 1) DronesScreen(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Drone Logbook'),
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

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, int> _settings = {
    'batteries_enabled': 0,
    'drones_enabled': 0,
  };
  bool _isSettingsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _dbHelper.getSettings();
    setState(() {
      _settings = settings;
    });
  }

  void _toggleSetting(String key) {
    setState(() {
      _settings[key] = _settings[key] == 1 ? 0 : 1;
    });
  }

  Future<void> _saveSettings() async {
    await _dbHelper.updateSettings(_settings);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Settings saved successfully! Please restart the app for changes to take effect.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home page'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 2.0,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Welcome to The Drone Logbook!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Use this app to manage your batteries, drones, and more. '
                        'You can enable or disable specific features below.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSettingsExpanded = !_isSettingsExpanded;
                  });
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: const Text(
                      'Settings',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Icon(
                      _isSettingsExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: const Color.fromARGB(255, 59, 131, 255),
                    ),
                  ),
                ),
              ),
              if (_isSettingsExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Enable Batteries'),
                            value: _settings['batteries_enabled'] == 1,
                            onChanged: (value) =>
                                _toggleSetting('batteries_enabled'),
                          ),
                          SwitchListTile(
                            title: const Text('Enable Drones'),
                            value: _settings['drones_enabled'] == 1,
                            onChanged: (value) =>
                                _toggleSetting('drones_enabled'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: _saveSettings,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              child: Text(
                                'Save Settings',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DronesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Drones list Screen (to be implemented)',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
