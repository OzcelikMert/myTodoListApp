import 'package:sqflite/sqflite.dart';

class DBTableCheckedItems {
  static const tableName = 'checkedItems';
  static const columnId = 'checkedItemId';
  static const columnCreatedAt = 'checkedItemCreatedAt';
  static const columnUpdatedAt = 'checkedItemUpdatedAt';
  static const columnItemId = 'checkedItemItemId';

  final Database db;
  DBTableCheckedItems(this.db);

  Future onCreate() async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnCreatedAt TEXT  NOT NULL,
        $columnUpdatedAt TEXT NOT NULL,
        $columnItemId INTEGER NOT NULL
      )
      ''');
  }

  Future onUpgrade() async {
    /*await db.execute("DROP TABLE IF EXISTS $tableName");
    await onCreate();*/
  }
}