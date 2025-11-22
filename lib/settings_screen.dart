import 'package:flutter/material.dart';
import 'database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, int> _settings = {
    'batteries_enabled': 0,
    'drones_enabled': 0,
    'inventory_enabled': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _dbHelper.getSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  void _toggleSetting(String key) {
    setState(() {
      _settings[key] = _settings[key] == 1 ? 0 : 1;
    });
  }

  Future<void> _saveSettings() async {
    await _dbHelper.updateSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Settings saved successfully! Please restart the app for changes to take effect.',
          ),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tune,
                                  color: Theme.of(context).primaryColor,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Feature Toggles',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enable or disable features in the app',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text(
                              'Batteries',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: const Text(
                              'Track and manage your drone batteries',
                            ),
                            value: _settings['batteries_enabled'] == 1,
                            onChanged: (value) =>
                                _toggleSetting('batteries_enabled'),
                            secondary: Icon(
                              Icons.battery_full,
                              color: _settings['batteries_enabled'] == 1
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text(
                              'Drones',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: const Text(
                              'Manage your drone fleet and flight logs',
                            ),
                            value: _settings['drones_enabled'] == 1,
                            onChanged: (value) =>
                                _toggleSetting('drones_enabled'),
                            secondary: Icon(
                              Icons.flight,
                              color: _settings['drones_enabled'] == 1
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text(
                              'Inventory',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: const Text(
                              'Keep track of your drone parts and accessories',
                            ),
                            value: _settings['inventory_enabled'] == 1,
                            onChanged: (value) =>
                                _toggleSetting('inventory_enabled'),
                            secondary: Icon(
                              Icons.inventory_2,
                              color: _settings['inventory_enabled'] == 1
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Save Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 1,
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Restart the app after saving to see changes in the navigation menu.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade900,
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
            ),
    );
  }
}

