import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class TaskDb {
  static Database? _db;
  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'chronox.db'),
      version: 1,
      onCreate: (d, v) => d.execute(
        'CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT,description TEXT,due INTEGER,priority INTEGER,locked INTEGER,completed INTEGER)',
      ),
    );
    return _db!;
  }

  static Future<List<Task>> all() async =>
      (await (await db).query('tasks', orderBy: 'completed ASC,due ASC'))
          .map(Task.from).toList();

  static Future<int> save(Task task) async {
    final database = await db;
    final values = task.map()..remove('id');
    if (task.id == null) return database.insert('tasks', values);
    await database.update('tasks', values, where: 'id=?', whereArgs: [task.id]);
    return task.id!;
  }

  static Future<void> delete(int id) async {
    await (await db).delete('tasks', where: 'id=?', whereArgs: [id]);
  }
}
