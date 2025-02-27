import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class StorageService extends GetxService {
  static Database? _database;
  static const String dbName = 'app_database.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    final bool dbExists = await databaseExists(path);

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (!dbExists) {
          await _createTables(db);
        } else {
          await _applyMigrations(db, oldVersion, newVersion);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE usuario (
        usuario_id INTEGER PRIMARY KEY, 
        rut TEXT, 
        token TEXT, 
        empresa TEXT, 
        fecha_hora_init_session TEXT, 
        activation_status TEXT, 
        code_sso TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE logs (
        log_id INTEGER PRIMARY KEY AUTOINCREMENT, 
        mensaje TEXT, 
        fecha_hora TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE marca (
        marca_id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER,
        p_device_id INTEGER NOT NULL,
        p_empresa INTEGER NOT NULL,
        p_rut TEXT NOT NULL,
        p_equipo INTEGER NOT NULL,
        p_geofence_id INTEGER NOT NULL,
        p_fecha_hora TEXT NOT NULL,
        p_sentido INT NOT NULL,
        p_tipo INTEGER NOT NULL,
        p_lat REAL NOT NULL,
        p_long REAL NOT NULL,
        p_sincronizado TEXT NOT NULL DEFAULT 'Pendiente',
        FOREIGN KEY(usuario_id) REFERENCES usuario(usuario_id)
      )
    ''');
  }

  Future<void> _applyMigrations(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE usuario ADD COLUMN code_sso TEXT;");
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS logs (
          log_id INTEGER PRIMARY KEY AUTOINCREMENT,
          mensaje TEXT,
          fecha_hora TEXT NOT NULL
        )
      ''');
    }
  }

  Future<int> insertRecord(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> getRecords(String table, {Map<String, dynamic>? where}) async {
    final db = await database;
    if (where == null || where.isEmpty) {
      return await db.query(table);
    } else {
      String whereString = where.keys.map((key) => "$key = ?").join(" AND ");
      List<dynamic> whereArgs = where.values.toList();
      return await db.query(table, where: whereString, whereArgs: whereArgs);
    }
  }

  Future<int> updateRecord(String table, Map<String, dynamic> updateData, Map<String, dynamic> where) async {
    final db = await database;
    String whereString = where.keys.map((key) => "$key = ?").join(" AND ");
    List<dynamic> whereArgs = where.values.toList();
    return await db.update(table, updateData, where: whereString, whereArgs: whereArgs);
  }

  Future<int> deleteRecord(String table, Map<String, dynamic> where) async {
    final db = await database;
    String whereString = where.keys.map((key) => "$key = ?").join(" AND ");
    List<dynamic> whereArgs = where.values.toList();
    return await db.delete(table, where: whereString, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> getLogs() async {
    final db = await database;
    return await db.query('logs', orderBy: 'log_id DESC', limit: 500);
  }

  Future<int> insertMarca(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('marca', data);
  }

  Future<List<Map<String, dynamic>>> getMarcas() async {
    final db = await database;
    return await db.query('marca');
  }

  Future<int> updateMarcaSync(int id) async {
    final db = await database;
    return await db.update('marca', {'p_sincronizado': 'Sincronizado'}, where: 'marca_id = ?', whereArgs: [id]);
  }

  Future<int> deleteMarca(int id) async {
    final db = await database;
    return await db.delete('marca', where: 'marca_id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getMarcasNoSync() async {
    final db = await database;
    return await db.query('marca', where: 'p_sincronizado = ?', whereArgs: ['Pendiente']);
  }
}
