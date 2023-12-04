import 'package:my_todo_list_app/config/db/tables/checkedItem.dart';
import 'package:my_todo_list_app/config/db/tables/item.dart';
import 'package:my_todo_list_app/lib/file.lib.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBConn {
  static const _databaseName = 'myTodoListApp.db';
  static const _databaseVersion = 14;

  DBConn._privateConstructor();
  static final DBConn instance = DBConn._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    var path = join((await FileLib.applicationDocumentDirectory).path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    var tableLanguages = DBTableItems(db);
    tableLanguages.onCreate();

    var tableWords = DBTableCheckedItems(db);
    tableWords.onCreate();
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    var tableLanguages = DBTableItems(db);
    tableLanguages.onUpgrade();

    var tableWords = DBTableCheckedItems(db);
    tableWords.onUpgrade();
  }
}