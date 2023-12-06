import 'package:my_todo_list_app/config/db/conn.dart';
import 'package:my_todo_list_app/config/db/tables/checkedItem.dart';
import 'package:my_todo_list_app/models/services/checkedItem.model.dart';

class CheckedItemService {
  static Future<List<CheckedItemGetResultModel>> get(CheckedItemGetParamModel params) async {
    List<CheckedItemGetResultModel> returnItems = [];
    String whereString = "";
    List<dynamic> whereArgs = [];

    if (params.checkedItemId != null) {
      whereString += "${DBTableCheckedItems.columnId} = ? AND ";
      whereArgs.add(params.checkedItemId);
    }

    if (params.checkedItemItemId != null) {
      whereString += "${DBTableCheckedItems.columnItemId} = ? AND ";
      whereArgs.add(params.checkedItemItemId);
    }

    if (params.checkedItemCreatedAt != null) {
      whereString += "${DBTableCheckedItems.columnCreatedAt} LIKE ? AND ";
      whereArgs.add('%${params.checkedItemCreatedAt?.substring(0, 10)}%');
    }

    var db = await DBConn.instance.database;
    var result = (await db.query(DBTableCheckedItems.tableName,
        where: whereString.isNotEmpty
            ? whereString.substring(0, whereString.length - 4)
            : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    ));

    for (var item in result) {
      returnItems.add(CheckedItemGetResultModel.fromJson(item));
    }

    return returnItems;
  }

  static Future<int> add(CheckedItemAddParamModel params) async {
    var date = DateTime.now().toUtc().toLocal().toString();

    var db = await DBConn.instance.database;
    return await db.insert(DBTableCheckedItems.tableName, {
      DBTableCheckedItems.columnItemId: params.checkedItemItemId,
      DBTableCheckedItems.columnCreatedAt: date,
      DBTableCheckedItems.columnUpdatedAt: date,
    });
  }

  static Future<int> addMulti(List<CheckedItemAddParamModel> paramsList) async {
    var date = DateTime.now().toUtc().toLocal().toString();

    var db = await DBConn.instance.database;
    final batch = db.batch();

    for(var params in paramsList) {
      batch.insert(DBTableCheckedItems.tableName, {
        DBTableCheckedItems.columnItemId: params.checkedItemItemId,
        DBTableCheckedItems.columnCreatedAt: date,
        DBTableCheckedItems.columnUpdatedAt: date,
      });
    }

    return (await batch.commit()).length;
  }

  static Future<int> delete(CheckedItemDeleteParamModel params) async {
    String whereString = "";
    List<dynamic> whereArgs = [];

    if (params.checkedItemId != null) {
      whereString += "${DBTableCheckedItems.columnId} = ? AND ";
      whereArgs.add(params.checkedItemId);
    }

    if (params.checkedItemItemId != null) {
      whereString += "${DBTableCheckedItems.columnItemId} = ? AND ";
      whereArgs.add(params.checkedItemItemId);
    }

    var db = await DBConn.instance.database;
    return await db.delete(DBTableCheckedItems.tableName,
        where: whereString.isNotEmpty
            ? whereString.substring(0, whereString.length - 4)
            : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null);
  }
}
