import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    // final path = join(dbPath, 'battery.db');

    // Uncomment the next line to clear the database during development
    // await _deleteDatabase(path);

    return openDatabase(
      join(dbPath, 'battery.db'),
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE batteries_type (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            min_voltage REAL NOT NULL,
            storage_voltage REAL NOT NULL,
            max_voltage REAL NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE batteries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            number TEXT,
            brand TEXT,
            description TEXT,
            battery_type_id INTEGER NOT NULL,
            buy_date DATE,
            end_date DATE,
            cell_count INTEGER NOT NULL,
            capacity INTEGER NOT NULL,
            storage_watt REAL,
            full_watt REAL,
            FOREIGN KEY (battery_type_id) REFERENCES batteries_type (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE battery_resistance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            battery_id INTEGER NOT NULL,
            resistance_c1 REAL,
            resistance_c2 REAL,
            resistance_c3 REAL,
            resistance_c4 REAL,
            resistance_c5 REAL,
            resistance_c6 REAL,
            resistance_c7 REAL,
            resistance_c8 REAL,
            resistance_c9 REAL,
            resistance_c10 REAL,
            date DATE DEFAULT (DATE('now')),
            FOREIGN KEY (battery_id) REFERENCES batteries (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            battery_id INTEGER,
            drone_id TEXT,
            resolved INTERGER DEFAULT 0,
            report_text TEXT NOT NULL,
            report_date DATE DEFAULT (DATE('now'))
          )
        ''');

        await db.execute('''
          CREATE TABLE usage (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            battery_id INTEGER,
            drone_id TEXT,
            usage_date DATE DEFAULT (DATE('now')),
            usage_count INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            firsttime INTERGER NOT NULL DEFAULT 0,
            firsttimebattery INTERGER NOT NULL DEFAULT 0,
            batteries_enabled INTEGER NOT NULL DEFAULT 0,
            drones_enabled INTEGER NOT NULL DEFAULT 0,
            expenses_enabled INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE drones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            frame TEXT,
            vtx TEXT,
            fc TEXT,
            motors TEXT,
            camera TEXT,
            props TEXT,
            esc TEXT,
            battery_id INTEGER,
            FOREIGN KEY (battery_id) REFERENCES batteries (id) ON DELETE SET NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            link TEXT,
            price REAL NOT NULL,
            count INTEGER NOT NULL DEFAULT 1,
            buy_date DATE NOT NULL
          )
        ''');
        await _insertDefaultData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          await db.execute(
              'ALTER TABLE reports ADD COLUMN resolved INTEGER DEFAULT 0');
        }
      },
    );
  }

  Future<void> _deleteDatabase(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await deleteDatabase(path);
      print('Database deleted at $path');
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    // Default battery types
    const defaultBatteryTypes = [
      {
        'type': 'LiPo',
        'min_voltage': 3.0,
        'storage_voltage': 3.8,
        'max_voltage': 4.2
      },
      {
        'type': 'Li-Ion',
        'min_voltage': 2.5,
        'storage_voltage': 3.8,
        'max_voltage': 4.2
      },
      {
        'type': 'NiMH',
        'min_voltage': 1.0,
        'storage_voltage': 1.2,
        'max_voltage': 1.5
      },
      {
        'type': 'Lead Acid',
        'min_voltage': 2.1,
        'storage_voltage': 2.2,
        'max_voltage': 2.4
      },
    ];
    for (var type in defaultBatteryTypes) {
      await db.insert('batteries_type', type);
    }

    // Default settings
    await db.insert('settings', {
      'firsttime': 1,
      'firsttimebattery': 1,
      'batteries_enabled': 1,
      'drones_enabled': 0,
      'expenses_enabled': 0,
    });
  }

  // Settings
  Future<Map<String, int>> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('settings');
    if (results.isNotEmpty) {
      return {
        'batteries_enabled': results[0]['batteries_enabled'],
        'drones_enabled': results[0]['drones_enabled'],
        'expenses_enabled': results[0]['expenses_enabled'],
      };
    }
    return {
      'batteries_enabled': 0,
      'drones_enabled': 0,
      'expenses_enabled': 0,
    };
  }

  Future<void> updateSettings(Map<String, int> settings) async {
    final db = await database;

    await db.update(
      'settings',
      settings,
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> getAllData() async {
    return {
      'Batteries': await getAllBatteries(),
      'Battery Resistance': await getAllResistances(),
      'Reports': await getAllReports(),
      'Usage': await getAllUsage(),
      'Expenses': await getAllExpenses(),
      'Drones': await getAllDrones(),
      'Settings': await getAllSettings(),
    };
  }

  Future<String> getDatabaseSQLDump() async {
    final db = await _initDatabase();

    // Get the list of tables
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
    );

    // Initialize the SQL dump
    final StringBuffer dump = StringBuffer();

    // Iterate through each table and get its schema and data
    for (final table in tables) {
      final tableName = table['name'];

      // Get the CREATE TABLE statement
      final createTableResult = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name='$tableName';",
      );
      if (createTableResult.isNotEmpty) {
        dump.writeln('${createTableResult.first['sql']};');
      }

      // Get the table data
      final data = await db.query(tableName as String);

      for (final row in data) {
        final columns = row.keys.map((key) => "'$key'").join(', ');
        final values = row.values
            .map((value) => value is String ? "'$value'" : value)
            .join(', ');
        dump.writeln("INSERT INTO $tableName ($columns) VALUES ($values);");
      }
      dump.writeln();
    }

    return dump.toString();
  }

  // batteries
  Future<List<Map<String, dynamic>>> getAllBatteries() async {
    final db = await database;

    return db.rawQuery('''
      SELECT b.*, bt.type,
        COALESCE((SELECT SUM(u.usage_count) 
          FROM usage AS u 
          WHERE u.battery_id = b.id), 0) AS total_usage_count
      FROM batteries AS b
      JOIN batteries_type AS bt ON b.battery_type_id = bt.id
      ORDER BY 
        CASE 
          WHEN b.end_date IS NULL THEN 0 
          ELSE 1 
        END,
        b.id;
  ''');
  }

  Future<List<Map<String, dynamic>>> getAllBatteriesWithDetails() async {
    final db = await database;
    return db.rawQuery('''
      SELECT b.*, bt.*, SUM(bu.usage_count) AS total_usage_count
      FROM batteries AS b, batteries_type AS bt, usage AS bu
      WHERE b.battery_type_id = bt.id
        AND b.id = bu.battery_id
        ORDER BY b.id
  ''');
  }

  Future<int> insertBattery(Map<String, dynamic> battery) async {
    final db = await database;
    return db.insert('batteries', battery);
  }

  Future<void> updateBattery(
    int id,
    String number,
    String brand,
    String description,
    String batteryTypeId,
    double capacity,
    String buyDate,
    int cellCount,
  ) async {
    final db = await database;

    // Calculate derived values
    final fullWatt = cellCount * 4.2 * capacity / 1000;
    final storageWatt = cellCount * 3.8 * capacity / 1000;

    // Log debug information
    // print('Updating battery: $id');
    // print(
    // 'Values: number=$number, brand=$brand, batteryTypeId=$batteryTypeId, capacity=$capacity, buyDate=$buyDate, cellCount=$cellCount');

    // Perform update
    await db.update(
      'batteries',
      {
        'number': number,
        'brand': brand,
        'description': description,
        'battery_type_id': int.tryParse(batteryTypeId),
        'capacity': capacity,
        'buy_date': buyDate,
        'cell_count': cellCount,
        'full_watt': fullWatt,
        'storage_watt': storageWatt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateBatteryEndDate(int id, DateTime endDate) async {
    final db = await database;
    await db.update(
      'batteries',
      {'end_date': endDate.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBattery(int id) async {
    final db = await database;

    return await db.delete(
      'batteries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // battery resistance
  Future<List<Map<String, dynamic>>> getAllResistances() async {
    final db = await database;
    return await db.query('battery_resistance ');
  }

  Future<int> addInternalResistance({
    required int batteryId,
    required Map<String, double> resistances,
    DateTime? date,
  }) async {
    final db = await database;
    final resistanceData = {
      'battery_id': batteryId,
      ...resistances,
      'date': date != null
          ? DateFormat('yyyy-MM-dd').format(date)
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };
    return await db.insert('battery_resistance', resistanceData);
  }

  Future<List<Map<String, dynamic>>> getResistancesForBattery(
      int batteryId) async {
    final db = await database;
    return db.query(
      'battery_resistance',
      where: 'battery_id = ?',
      whereArgs: [batteryId],
      orderBy: 'date DESC',
    );
  }

  Future<void> deleteResistance(int resistanceId) async {
    final db = await database;
    await db.delete('battery_resistance',
        where: 'id = ?', whereArgs: [resistanceId]);
  }

  // battery Reports
  Future<int> insertReport(
      int batteryId, String reportText, DateTime reportDate) async {
    final db = await database;

    // Format the date to store in the database (e.g., 'yyyy-MM-dd')
    final formattedDate = DateFormat('yyyy-MM-dd').format(reportDate);

    return db.insert('reports', {
      'battery_id': batteryId,
      'report_text': reportText,
      'report_date': formattedDate,
    });
  }

  Future<List<Map<String, dynamic>>> getReportsForBattery(int batteryId) async {
    final db = await database;
    return db.query(
      'reports',
      where: 'battery_id = ?',
      whereArgs: [batteryId],
      orderBy:
          'report_date DESC',
    );
  }

  Future<void> fixReport(int reportId) async {
    final db = await database;
    await db.update(
      'reports',
      {'resolved': 1},
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }

  Future<void> deleteReport(int reportId) async {
    final db = await database;
    await db.delete('reports', where: 'id = ?', whereArgs: [reportId]);
  }

  // battery Usage
  Future<int> insertUsage(int batteryId, String usageDate, int count) async {
    final db = await database;
    return db.insert('usage', {
      'battery_id': batteryId,
      'usage_date': usageDate,
      'usage_count': count,
    });
  }

  Future<List<Map<String, dynamic>>> getUsageForBattery(int batteryId) async {
    final db = await database;
    return db.query(
      'usage',
      where: 'battery_id = ?',
      whereArgs: [batteryId],
      orderBy:
          'usage_date DESC',
    );
  }

  Future<void> deleteUsage(int usageId) async {
    final db = await database;
    await db.delete('usage', where: 'id = ?', whereArgs: [usageId]);
  }

  // for debug database on run
  Future<List<Map<String, dynamic>>> getAllReports() async {
    final db = await database;
    return db.query('reports');
  }

  Future<List<Map<String, dynamic>>> getAllUsage() async {
    final db = await database;
    return db.query('usage');
  }

  Future<List<Map<String, dynamic>>> getAllBatteryTypes() async {
    final db = await database;
    return await db.query('batteries_type');
  }

  Future<List<Map<String, dynamic>>> getAllSettings() async {
    final db = await database;
    return await db.query('settings');
  }

  Future<List<Map<String, dynamic>>> getAllDrones() async {
    final db = await database;
    return await db.query('drones');
  }

  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final db = await database;
    return await db.query('expenses');
  }
}
