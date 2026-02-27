import 'package:sqflite/sqflite.dart' show Database, openDatabase, getDatabasesPath, ConflictAlgorithm;
import 'package:path/path.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart' show AppDatabaseException;

/// SQLite 3.x veritabanı yöneticisi.
///
/// Singleton pattern ile uygulama genelinde tek bir bağlantı havuzu kullanılır.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // ── Veritabanı Başlatma ───────────────────────────────────────────────────

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, AppConstants.dbName);

      return await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
        // WAL modu: openDatabase parametresiyle etkinleştirilir (API 35+ uyumlu)
        singleInstance: true,
      );
    } catch (e) {
      throw AppDatabaseException('Veritabanı başlatılamadı.', e);
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute(_createUsersTable);
      await txn.execute(_createTasksTable);
      await txn.execute(_createRemindersTable);
      await txn.execute(_createTasksIndex);
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // completed_at: görevin tamamlanma zamanı (1 günlük görünürlük için)
      await db.execute(
        'ALTER TABLE ${AppConstants.tableTasks} ADD COLUMN completed_at TEXT',
      );
    }
  }

  // ── DDL: Tablo Şemaları ───────────────────────────────────────────────────

  static const String _createUsersTable = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableUsers} (
      id          TEXT PRIMARY KEY,
      name        TEXT NOT NULL,
      avatar_path TEXT NOT NULL DEFAULT '',
      pin         TEXT NOT NULL,
      role        TEXT NOT NULL DEFAULT 'member',
      language    TEXT NOT NULL DEFAULT 'tr_TR',
      voice_enabled        INTEGER NOT NULL DEFAULT 1,
      notifications_enabled INTEGER NOT NULL DEFAULT 1,
      tts_speed   REAL NOT NULL DEFAULT 1.0,
      tts_pitch   REAL NOT NULL DEFAULT 1.0,
      created_at  TEXT NOT NULL,
      last_login_at TEXT
    )
  ''';

  static const String _createTasksTable = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableTasks} (
      id           TEXT PRIMARY KEY,
      user_id      TEXT NOT NULL,
      title        TEXT NOT NULL,
      description  TEXT,
      is_completed INTEGER NOT NULL DEFAULT 0,
      completed_at TEXT,
      priority     TEXT NOT NULL DEFAULT 'medium',
      category     TEXT NOT NULL DEFAULT 'general',
      tags         TEXT NOT NULL DEFAULT '[]',
      due_date     TEXT,
      reminder_at  TEXT,
      created_at   TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES ${AppConstants.tableUsers}(id)
        ON DELETE CASCADE
    )
  ''';

  static const String _createRemindersTable = '''
    CREATE TABLE IF NOT EXISTS ${AppConstants.tableReminders} (
      id              TEXT PRIMARY KEY,
      task_id         TEXT NOT NULL,
      scheduled_at    TEXT NOT NULL,
      is_fired        INTEGER NOT NULL DEFAULT 0,
      notification_id INTEGER NOT NULL,
      FOREIGN KEY (task_id) REFERENCES ${AppConstants.tableTasks}(id)
        ON DELETE CASCADE
    )
  ''';

  static const String _createTasksIndex = '''
    CREATE INDEX IF NOT EXISTS idx_tasks_user_id
    ON ${AppConstants.tableTasks}(user_id)
  ''';

  // ── Genel CRUD Yardımcıları ───────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> row) async {
    try {
      final db = await database;
      return await db.insert(
        table,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw AppDatabaseException('INSERT hatası: $table', e);
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    try {
      final db = await database;
      return await db.query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
      );
    } catch (e) {
      throw AppDatabaseException('QUERY hatası: $table', e);
    }
  }

  Future<int> update(
    String table,
    Map<String, dynamic> row, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.update(table, row, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw AppDatabaseException('UPDATE hatası: $table', e);
    }
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw AppDatabaseException('DELETE hatası: $table', e);
    }
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? args,
  ]) async {
    try {
      final db = await database;
      return await db.rawQuery(sql, args);
    } catch (e) {
      throw AppDatabaseException('RAW QUERY hatası', e);
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
