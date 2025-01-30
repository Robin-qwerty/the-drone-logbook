import 'batteries/battery_list_screen.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'home_screen.dart';

void main() {
  runApp(MyApp());
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
      home: MainScreen(),
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
    'expenses_enabled': 0,
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
    final batteryResistance = await _dbHelper.getAllBatteryResistances();
    final reports = await _dbHelper.getAllReports();
    final usage = await _dbHelper.getAllUsage();
    final expenses = await _dbHelper.getAllExpenses();
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

    print('\nExpenses:');
    for (var entry in expenses) {
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
        if (settings['batteries_enabled'] == 0 ||
            settings['drones_enabled'] == 0 ||
            settings['expenses_enabled'] == 0)
          const HomeScreen(),
        if (settings['batteries_enabled'] == 1) const BatteryListScreen(),
        if (settings['drones_enabled'] == 1) const DronesScreen(),
        if (settings['expenses_enabled'] == 1) const ExpensesScreen(),
      ];

      _bottomNavItems = [
        if (settings['batteries_enabled'] == 0 ||
            settings['drones_enabled'] == 0 ||
            settings['expenses_enabled'] == 0)
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
        if (settings['expenses_enabled'] == 1)
          const BottomNavigationBarItem(
            icon: Icon(Icons.flight),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Drone Logbook'),
        leading: (_settings.values.every((value) => value == 1))
            ? IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
              )
            : null, // Hide home icon if not all settings are 1
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

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final DatabaseHelper _dbHelper = DatabaseHelper();
//   Map<String, int> _settings = {
//     'batteries_enabled': 0,
//     'drones_enabled': 0,
//   };
//   bool _isSettingsExpanded = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadSettings();
//   }

//   Future<void> _loadSettings() async {
//     final settings = await _dbHelper.getSettings();
//     setState(() {
//       _settings = settings;
//     });
//   }

//   void _toggleSetting(String key) {
//     setState(() {
//       _settings[key] = _settings[key] == 1 ? 0 : 1;
//     });
//   }

//   Future<void> _saveSettings() async {
//     await _dbHelper.updateSettings(_settings);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text(
//           'Settings saved successfully! Please restart the app for changes to take effect.',
//         ),
//       ),
//     );
//   }

//   Future<void> _requestStoragePermission() async {
//     if (await Permission.storage.request().isDenied) {
//       throw Exception("Storage permission denied.");
//     }
//   }

//   Future<void> _exportToSQL(BuildContext context) async {
//     try {
//       // Get the Downloads directory
//       final downloadsDirectory = Directory('/storage/emulated/0/Download');
//       if (!await downloadsDirectory.exists()) {
//         throw Exception("Downloads folder not accessible.");
//       }

//       // Define the SQL file path
//       final sqlFile = File('${downloadsDirectory.path}/database_export.sql');

//       // Generate the SQL dump
//       final sqlDump = await _dbHelper.getDatabaseSQLDump();

//       // Write the SQL dump to the file
//       await sqlFile.writeAsString(sqlDump);

//       // Show success message with file path
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('SQL file saved to Downloads: ${sqlFile.path}')),
//       );
//     } catch (e) {
//       // Show error message if something goes wrong
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error saving SQL file: $e')),
//       );
//     }
//   }

//   Future<void> _exportToCSV() async {
//     try {
//       final path = await ExternalPath.getExternalStoragePublicDirectory(
//           ExternalPath.DIRECTORY_DOWNLOADS);
//       final csvFile = File('$path/database_export.csv');
//       final data = await _dbHelper.getAllData();
//       final csvData = const ListToCsvConverter().convert(data as List<List?>?);
//       await csvFile.writeAsString(csvData);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('CSV exported to ${csvFile.path}')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error exporting CSV: $e')),
//       );
//     }
//   }

//   Future<void> _exportToPDF() async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final pdfFile = File('${directory.path}/database_export.pdf');
//       final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
//       final font = pw.Font.ttf(fontData);
//       final pdf = pw.Document();
//       final data = await _dbHelper
//           .getAllData(); // Combine all tables into a single structure
//       pdf.addPage(
//         pw.Page(
//           build: (pw.Context context) {
//             return pw.Column(
//               children: data.entries.map((entry) {
//                 return pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text(
//                       entry.key,
//                       style: pw.TextStyle(
//                           font: font,
//                           fontSize: 18,
//                           fontWeight: pw.FontWeight.bold),
//                     ),
//                     pw.Text(entry.value.toString(),
//                         style: pw.TextStyle(font: font)),
//                     pw.SizedBox(height: 10),
//                   ],
//                 );
//               }).toList(),
//             );
//           },
//         ),
//       );
//       await pdfFile.writeAsBytes(await pdf.save());
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('PDF file exported to ${pdfFile.path}')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error exporting PDF: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Home page'),
//         backgroundColor: const Color.fromARGB(255, 255, 255, 255),
//         elevation: 2.0,
//       ),
//       body: SingleChildScrollView(
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.blue.shade50, Colors.blue.shade50],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                 ),
//                 child: const Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Welcome to The Drone Logbook!',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       SizedBox(height: 10),
//                       Text(
//                         'Use this app to manage your batteries, drones, and more. '
//                         'You can enable or disable specific features below.',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.black54,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _isSettingsExpanded = !_isSettingsExpanded;
//                   });
//                 },
//                 child: Card(
//                   elevation: 3,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10.0),
//                   ),
//                   child: ListTile(
//                     title: const Text(
//                       'Settings',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     trailing: Icon(
//                       _isSettingsExpanded
//                           ? Icons.expand_less
//                           : Icons.expand_more,
//                       color: const Color.fromARGB(255, 59, 131, 255),
//                     ),
//                   ),
//                 ),
//               ),
//               if (_isSettingsExpanded)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 10.0),
//                   child: Card(
//                     elevation: 3,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16.0, vertical: 10.0),
//                       child: Column(
//                         children: [
//                           SwitchListTile(
//                             title: const Text('Enable Batteries'),
//                             value: _settings['batteries_enabled'] == 1,
//                             onChanged: (value) =>
//                                 _toggleSetting('batteries_enabled'),
//                           ),
//                           SwitchListTile(
//                             title: const Text('Enable Drones'),
//                             value: _settings['drones_enabled'] == 1,
//                             onChanged: (value) =>
//                                 _toggleSetting('drones_enabled'),
//                           ),
//                           SwitchListTile(
//                             title: const Text('Enable expenses'),
//                             value: _settings['expenses_enabled'] == 1,
//                             onChanged: (value) =>
//                                 _toggleSetting('expenses_enabled'),
//                           ),
//                           const SizedBox(height: 10),
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blueAccent,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10.0),
//                               ),
//                             ),
//                             onPressed: _saveSettings,
//                             child: const Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 20.0, vertical: 10.0),
//                               child: Text(
//                                 'Save Settings',
//                                 style: TextStyle(fontSize: 16),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           const Divider(),
//                           const SizedBox(height: 16),
//                           const Text(
//                             'Export Options',
//                             style: TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.bold),
//                             textAlign: TextAlign.center,
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             children: [
//                               ElevatedButton.icon(
//                                 onPressed: () async {
//                                   try {
//                                     await _requestStoragePermission();
//                                     await _exportToSQL(context);
//                                   } catch (e) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(content: Text('Error: $e')),
//                                     );
//                                   }
//                                 },
//                                 icon: const Icon(Icons.storage),
//                                 label: const Text('SQL'),
//                               ),
//                               ElevatedButton.icon(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blue,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10.0),
//                                   ),
//                                 ),
//                                 onPressed: _exportToCSV,
//                                 icon: const Icon(Icons.table_chart),
//                                 label: const Text('CSV'),
//                               ),
//                               ElevatedButton.icon(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.red,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10.0),
//                                   ),
//                                 ),
//                                 onPressed: _exportToPDF,
//                                 icon: const Icon(Icons.picture_as_pdf),
//                                 label: const Text('PDF'),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class DronesScreen extends StatelessWidget {
  const DronesScreen({super.key});

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

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Expenses list Screen (to be implemented)',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
