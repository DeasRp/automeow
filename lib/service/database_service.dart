import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('automeow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Feed History Table
    await db.execute('''
      CREATE TABLE feed_history (
        id $idType,
        timestamp $textType,
        amount $realType,
        action $textType
      )
    ''');

    // Schedules Table
    await db.execute('''
      CREATE TABLE schedules (
        id $idType,
        slot_index $integerType,
        hour $integerType,
        minute $integerType,
        duration $integerType,
        enabled $integerType,
        label $textType
      )
    ''');

    // Sensor Readings Table
    await db.execute('''
      CREATE TABLE sensor_readings (
        id $idType,
        timestamp $textType,
        weight $realType,
        stock_level $integerType
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
        'CREATE INDEX idx_feed_history_timestamp ON feed_history(timestamp DESC)');
    await db.execute(
        'CREATE INDEX idx_sensor_readings_timestamp ON sensor_readings(timestamp DESC)');
  }

  // ==================== FEED HISTORY OPERATIONS ====================

  /// Insert a new feed history record
  Future<int> insertFeedHistory({
    required DateTime timestamp,
    required double amount,
    required String action,
  }) async {
    final db = await database;
    return await db.insert('feed_history', {
      'timestamp': timestamp.toIso8601String(),
      'amount': amount,
      'action': action,
    });
  }

  /// Get all feed history records, ordered by most recent first
  Future<List<Map<String, dynamic>>> getAllFeedHistory() async {
    final db = await database;
    final result = await db.query(
      'feed_history',
      orderBy: 'timestamp DESC',
    );

    return result.map((row) {
      return {
        'id': row['id'],
        'time': DateTime.parse(row['timestamp'] as String),
        'amount': row['amount'],
        'action': row['action'],
      };
    }).toList();
  }

  /// Get feed history within a date range
  Future<List<Map<String, dynamic>>> getFeedHistoryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final result = await db.query(
      'feed_history',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return result.map((row) {
      return {
        'id': row['id'],
        'time': DateTime.parse(row['timestamp'] as String),
        'amount': row['amount'],
        'action': row['action'],
      };
    }).toList();
  }

  /// Delete old feed history records (keep only last N days)
  Future<int> deleteOldFeedHistory({int daysToKeep = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    return await db.delete(
      'feed_history',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  /// Clear all feed history
  Future<int> clearAllFeedHistory() async {
    final db = await database;
    return await db.delete('feed_history');
  }

  // ==================== SCHEDULES OPERATIONS ====================

  /// Insert or update a schedule
  Future<int> upsertSchedule({
    required int slotIndex,
    required int hour,
    required int minute,
    required int duration,
    required bool enabled,
    required String label,
  }) async {
    final db = await database;

    // Check if schedule exists for this slot
    final existing = await db.query(
      'schedules',
      where: 'slot_index = ?',
      whereArgs: [slotIndex],
    );

    if (existing.isEmpty) {
      // Insert new schedule
      return await db.insert('schedules', {
        'slot_index': slotIndex,
        'hour': hour,
        'minute': minute,
        'duration': duration,
        'enabled': enabled ? 1 : 0,
        'label': label,
      });
    } else {
      // Update existing schedule
      return await db.update(
        'schedules',
        {
          'hour': hour,
          'minute': minute,
          'duration': duration,
          'enabled': enabled ? 1 : 0,
          'label': label,
        },
        where: 'slot_index = ?',
        whereArgs: [slotIndex],
      );
    }
  }

  /// Get all schedules ordered by slot index
  Future<List<Map<String, dynamic>>> getAllSchedules() async {
    final db = await database;
    final result = await db.query(
      'schedules',
      orderBy: 'slot_index ASC',
    );

    return result.map((row) {
      return {
        'slot_index': row['slot_index'],
        'time': TimeOfDay(
          hour: row['hour'] as int,
          minute: row['minute'] as int,
        ),
        'duration': row['duration'],
        'enabled': (row['enabled'] as int) == 1,
        'label': row['label'],
      };
    }).toList();
  }

  /// Get a specific schedule by slot index
  Future<Map<String, dynamic>?> getScheduleBySlot(int slotIndex) async {
    final db = await database;
    final result = await db.query(
      'schedules',
      where: 'slot_index = ?',
      whereArgs: [slotIndex],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return {
      'slot_index': row['slot_index'],
      'time': TimeOfDay(
        hour: row['hour'] as int,
        minute: row['minute'] as int,
      ),
      'duration': row['duration'],
      'enabled': (row['enabled'] as int) == 1,
      'label': row['label'],
    };
  }

  /// Delete all schedules
  Future<int> clearAllSchedules() async {
    final db = await database;
    return await db.delete('schedules');
  }

  // ==================== SENSOR READINGS OPERATIONS ====================

  /// Insert a new sensor reading
  Future<int> insertSensorReading({
    required DateTime timestamp,
    required double weight,
    required int stockLevel,
  }) async {
    final db = await database;
    return await db.insert('sensor_readings', {
      'timestamp': timestamp.toIso8601String(),
      'weight': weight,
      'stock_level': stockLevel,
    });
  }

  /// Get all sensor readings
  Future<List<Map<String, dynamic>>> getAllSensorReadings() async {
    final db = await database;
    final result = await db.query(
      'sensor_readings',
      orderBy: 'timestamp DESC',
    );

    return result.map((row) {
      return {
        'id': row['id'],
        'timestamp': DateTime.parse(row['timestamp'] as String),
        'weight': row['weight'],
        'stock_level': row['stock_level'],
      };
    }).toList();
  }

  /// Get sensor readings within a date range
  Future<List<Map<String, dynamic>>> getSensorReadingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final result = await db.query(
      'sensor_readings',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    return result.map((row) {
      return {
        'id': row['id'],
        'timestamp': DateTime.parse(row['timestamp'] as String),
        'weight': row['weight'],
        'stock_level': row['stock_level'],
      };
    }).toList();
  }

  /// Get latest sensor reading
  Future<Map<String, dynamic>?> getLatestSensorReading() async {
    final db = await database;
    final result = await db.query(
      'sensor_readings',
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return {
      'id': row['id'],
      'timestamp': DateTime.parse(row['timestamp'] as String),
      'weight': row['weight'],
      'stock_level': row['stock_level'],
    };
  }

  /// Delete old sensor readings (keep only last N days)
  Future<int> deleteOldSensorReadings({int daysToKeep = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    return await db.delete(
      'sensor_readings',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  /// Clear all sensor readings
  Future<int> clearAllSensorReadings() async {
    final db = await database;
    return await db.delete('sensor_readings');
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Close the database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Delete the entire database (for testing or reset purposes)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'automeow.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
