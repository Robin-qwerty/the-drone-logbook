import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
    return openDatabase(
      join(dbPath, 'battery.db'),
      version: 4, // Incremented version
      onCreate: (db, version) async {
        // Create `batteries_type` table
        await db.execute('''
        CREATE TABLE batteries_type (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          min_voltage REAL NOT NULL,
          storage_voltage REAL NOT NULL,
          max_voltage REAL NOT NULL
        )
      ''');

        // Create `batteries` table
        await db.execute('''
        CREATE TABLE batteries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          number TEXT,
          brand TEXT,
          type_id INTEGER NOT NULL,
          buy_date DATE,
          end_date DATE,
          cell_count INTEGER NOT NULL,
          capacity INTEGER NOT NULL,
          storage_watt REAL,
          full_watt REAL,
          FOREIGN KEY (type_id) REFERENCES batteries_type (id) ON DELETE CASCADE
        )
      ''');

        // Create `reports` table
        await db.execute('''
        CREATE TABLE reports (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id INTEGER NOT NULL,
          item_type TEXT NOT NULL,
          report_text TEXT NOT NULL,
          report_date DATE DEFAULT (DATE('now'))
        )
      ''');

        // Create `usage` 
        await db.execute('''
        CREATE TABLE usage (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id INTEGER NOT NULL,
          item_type TEXT NOT NULL,
          usage_date DATE DEFAULT (DATE('now')),
          usage_count INTEGER NOT NULL DEFAULT 1
        )
      ''');

        // Create `settings` table
        await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          batteries_enabled INTEGER NOT NULL DEFAULT 1,
          drones_enabled INTEGER NOT NULL DEFAULT 1,
          expenses_enabled INTEGER NOT NULL DEFAULT 1
        )
      ''');

        // Create `drones` table
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

        // Create `expenses` table
        await db.execute('''
        CREATE TABLE expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          link TEXT,
          price REAL NOT NULL,
          buy_date DATE NOT NULL
        )
      ''');
        // Insert default data
        await _insertDefaultData(db);
      },
    );
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
      'batteries_enabled': 1,
      'drones_enabled': 1,
      'expenses_enabled': 1,
    });
  }

  // Settings
  Future<Map<String, dynamic>> getSettings() async {
    final db = await database;
    final result = await db.query('settings', limit: 1);
    return result.isNotEmpty ? result.first : {};
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final db = await database;
    await db.update('settings', settings);
  }

  // batteries
  Future<List<Map<String, dynamic>>> getAllBatteries() async {
    final db = await database;

    // Query to get battery details and their usage count
    final result = await db.rawQuery('''
    SELECT b.*, bt.type,
           (SELECT COUNT(u.id) 
            FROM usage AS u 
            WHERE u.item_id = b.id AND u.item_type = '1') AS usage_count
    FROM batteries AS b, batteries_type AS bt
    WHERE b.type_id = bt.id
    ORDER BY b.id
  ''');

    return result;
  }

  Future<List<Map<String, dynamic>>> getAllBatteriesWithDetails() async {
    final db = await database;
    return db.rawQuery('''
    SELECT b.*, bt.*, bu.usage_count
    FROM batteries AS b, batteries_type AS bt, usage AS bu
    WHERE b.type_id = bt.id
    AND b.id = bu.item_id
    AND bu.item_type = '1'
    ORDER BY b.id
  ''');
  }

  Future<int> insertBattery(Map<String, dynamic> battery) async {
    final db = await database;
    return db.insert('batteries', battery);
  }

  Future<void> updateBattery(int id, String number, String typeId,
      double capacity, String buyDate, int cellCount) async {
    final db = await database;

    final full = cellCount * 4.2 * capacity / 1000;

    final storageWatt = cellCount * 4.2 * capacity / 1000 / 2;

    await db.update(
      'batteries',
      {
        'number': number,
        'type_id': typeId,
        'capacity': capacity,
        'buy_date': buyDate,
        'cell_count': cellCount,
        'full_watt': full,
        'storage_watt': storageWatt,
      },
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

  // Future<List<Map<String, dynamic>>> getBatteryUsageForBattery(
  //     int batteryId) async {
  //   final db = await database;
  //   return db.query('usage', where: 'battery_id = ?', whereArgs: [batteryId]);
  // }

  // Future<void> insertBatteryUsage(
  //     int batteryId, String usageDate, int usageCount) async {
  //   final db = await database;
  //   await db.insert('usage', {
  //     'battery_id': batteryId,
  //     'usage_date': usageDate,
  //     'usage_count': usageCount,
  //   });
  // }

  // Reports
  Future<int> insertReport(
      int itemId, String itemType, String reportText, DateTime reportDate) async {
    final db = await database;

    // Format the date to store in the database (e.g., 'yyyy-MM-dd')
    final formattedDate = DateFormat('yyyy-MM-dd').format(reportDate);

    return db.insert('reports', {
      'item_id': itemId,
      'item_type': itemType,
      'report_text': reportText,
      'report_date': formattedDate,
    });
  }

  Future<List<Map<String, dynamic>>> getReports(int itemId, String itemType) async {
    final db = await database;
    return db.query('reports', where: 'item_id = ?', whereArgs: [itemId]);
  }



  // Usage
  Future<int> insertUsage(int itemId, String itemType, String usageDate, int count) async {
    final db = await database;
    return db.insert('usage', {
      'item_id': itemId,
      'item_type': itemType,
      'usage_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'usage_count': count,
    });
  }

  Future<List<Map<String, dynamic>>> getUsageForItem(
      int itemId, String itemType) async {
    final db = await database;
    return db.query('usage',
        where: 'item_id = ? AND item_type = ?', whereArgs: [itemId, itemType]);
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
