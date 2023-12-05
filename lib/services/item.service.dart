import 'package:my_todo_list_app/config/db/conn.dart';
import 'package:my_todo_list_app/config/db/tables/item.dart';
import 'package:my_todo_list_app/models/services/item.model.dart';

class ItemService {
  static Future<List<ItemGetResultModel>> get(ItemGetParamModel params) async {
    List<ItemGetResultModel> returnItems = [];
    String whereString = "";
    List<dynamic> whereArgs = [];

    if (params.itemId != null) {
      whereString += "${DBTableItems.columnId} = ? AND ";
      whereArgs.add(params.itemId);
    }

    if (params.itemDayId != null) {
      whereString += "${DBTableItems.columnDayId} = ? AND ";
      whereArgs.add(params.itemDayId);
    }

    if (params.itemText != null) {
      whereString += "${DBTableItems.columnText} LIKE ? AND ";
      whereArgs.add('%${params.itemText}%');
    }

    if (params.itemIsDeleted != null) {
      whereString += "${DBTableItems.columnIsDeleted} = ? AND ";
      whereArgs.add(params.itemIsDeleted);
    }

    var db = await DBConn.instance.database;
    var result = (await db.query(DBTableItems.tableName,
        where: whereString.isNotEmpty
            ? whereString.substring(0, whereString.length - 4)
            : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null));

    for (var item in result) {
      returnItems.add(ItemGetResultModel.fromJson(item));
    }

    return returnItems;
  }

  static Future<int> add(ItemAddParamModel params) async {
    var date = DateTime.now().toUtc().toString();

    var db = await DBConn.instance.database;
    return await db.insert(DBTableItems.tableName, {
      DBTableItems.columnDayId: params.itemDayId,
      DBTableItems.columnText: params.itemText,
      DBTableItems.columnIsDeleted: 0,
      DBTableItems.columnCreatedAt: date,
      DBTableItems.columnUpdatedAt: date,
    });
  }

  static Future<int> addMulti(List<ItemAddParamModel> paramsList) async {
    var date = DateTime.now().toUtc().toString();

    var db = await DBConn.instance.database;
    final batch = db.batch();

    for(var params in paramsList) {
      batch.insert(DBTableItems.tableName, {
        DBTableItems.columnDayId: params.itemDayId,
        DBTableItems.columnText: params.itemText,
        DBTableItems.columnIsDeleted: 0,
        DBTableItems.columnCreatedAt: date,
        DBTableItems.columnUpdatedAt: date,
      });
    }

    return (await batch.commit()).length;
  }

  static Future<int> update(ItemUpdateParamModel params) async {
    var date = DateTime.now().toUtc().toString();

    Map<String, dynamic> setMap = {
      DBTableItems.columnUpdatedAt: date
    };

    String whereString = "";
    List<dynamic> whereArgs = [];

    if (params.whereItemId != null) {
      whereString += "${DBTableItems.columnId} = ? AND ";
      whereArgs.add(params.whereItemId);
    }

    if (params.itemText != null) {
      setMap[DBTableItems.columnText] = params.itemText;
    }

    if (params.itemDayId != null) {
      setMap[DBTableItems.columnDayId] = params.itemDayId;
    }

    var db = await DBConn.instance.database;
    var update = await db.update(
      DBTableItems.tableName,
      setMap,
      where: whereString.isNotEmpty
          ? whereString.substring(0, whereString.length - 4)
          : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return update;
  }

  static Future<int> delete(ItemDeleteParamModel params) async {
    var date = DateTime.now().toUtc().toString();

    Map<String, dynamic> setMap = {
      DBTableItems.columnUpdatedAt: date,
      DBTableItems.columnIsDeleted: 1
    };

    String whereString = "";
    List<dynamic> whereArgs = [];

    if (params.itemId != null) {
      whereString += "${DBTableItems.columnId} = ? AND ";
      whereArgs.add(params.itemId);
    }

    var db = await DBConn.instance.database;
    return await db.update(DBTableItems.tableName,
        setMap,
        where: whereString.isNotEmpty
            ? whereString.substring(0, whereString.length - 4)
            : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null);
  }
}
