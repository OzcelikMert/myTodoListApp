import 'package:sqflite/sqflite.dart';

class DBTableCheckedItems {
  static const tableName = 'checkedItems';
  static const columnId = 'checkedItemId';
  static const columnItemId = 'checkedItemItemId';
  static const columnCreatedAt = 'checkedItemCreatedAt';
  static const columnUpdatedAt = 'checkedItemUpdatedAt';

  final Database db;
  DBTableCheckedItems(this.db);

  Future onCreate() async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnItemId INTEGER NOT NULL,
        $columnCreatedAt TEXT  NOT NULL,
        $columnUpdatedAt TEXT NOT NULL
      )
      ''');
  }

  Future onUpgrade() async {
    /*await db.execute("DROP TABLE IF EXISTS $tableName");
    await onCreate();*/
  }
}