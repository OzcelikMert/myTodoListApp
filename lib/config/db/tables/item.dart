import 'package:sqflite/sqflite.dart';

class DBTableItems {
  static const tableName = 'items';
  static const columnId = 'itemId';
  static const columnCreatedAt = 'itemCreatedAt';
  static const columnUpdatedAt = 'itemUpdatedAt';
  static const columnText = 'itemText';
  static const columnDayId = 'itemDayId';
  static const columnIsDeleted = 'itemIsDeleted';

  final Database db;
  DBTableItems(this.db);

  Future onCreate() async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnCreatedAt TEXT  NOT NULL,
        $columnUpdatedAt TEXT NOT NULL,
        $columnText TEXT NOT NULL,
        $columnDayId INTEGER NOT NULL,
        $columnIsDeleted INTEGER NOT NULL
      )
      ''');
  }

  Future onUpgrade() async {
    /*await db.execute("DROP TABLE IF EXISTS $tableName");
    await onCreate();*/
  }
}