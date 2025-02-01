import 'package:flutter/material.dart';
import 'database_helper.dart';

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
    'expenses_enabled': 0,
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
        backgroundColor: Colors.white,
        elevation: 2.0,
      ),
      body: SingleChildScrollView(
        child: Container(
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
                        'Use this app to manage your batteries, drones, and more.',
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
                      color: Colors.blue,
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
                      padding: const EdgeInsets.all(16.0),
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
                          SwitchListTile(
                            title: const Text('Enable Expenses'),
                            value: _settings['expenses_enabled'] == 1,
                            onChanged: (value) =>
                                _toggleSetting('expenses_enabled'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _saveSettings,
                            child: const Text('Save Settings'),
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
