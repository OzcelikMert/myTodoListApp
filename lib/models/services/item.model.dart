import 'package:my_todo_list_app/config/db/tables/item.dart';

class ItemGetResultModel {
  final int itemId;
  final int itemDayId;
  late final String itemText;
  final String itemCreatedAt;
  final String itemUpdatedAt;
  final int itemIsDeleted;

  ItemGetResultModel({
    required this.itemId,
    required this.itemDayId,
    required this.itemText,
    required this.itemCreatedAt,
    required this.itemUpdatedAt,
    required this.itemIsDeleted
  });

  Map<String, dynamic> toJson() {
    return {
      DBTableItems.columnId: itemId,
      DBTableItems.columnDayId: itemDayId,
      DBTableItems.columnText: itemText,
      DBTableItems.columnCreatedAt: itemCreatedAt,
      DBTableItems.columnUpdatedAt: itemUpdatedAt,
      DBTableItems.columnIsDeleted: itemIsDeleted,
    };
  }

  static ItemGetResultModel fromJson(Map<String, dynamic> json) {
    return ItemGetResultModel(
        itemId: int.tryParse(json[DBTableItems.columnId].toString()) ?? 0,
        itemDayId: int.tryParse(json[DBTableItems.columnDayId].toString()) ?? 0,
        itemText: json[DBTableItems.columnText].toString(),
        itemCreatedAt: json[DBTableItems.columnCreatedAt].toString(),
        itemUpdatedAt: json[DBTableItems.columnUpdatedAt].toString(),
        itemIsDeleted: int.tryParse(json[DBTableItems.columnIsDeleted].toString()) ?? 0,
    );
  }
}

class ItemGetParamModel {
  final int? itemId;
  final int? itemDayId;
  final String? itemText;
  final int? itemIsDeleted;

  ItemGetParamModel({
    this.itemId,
    this.itemDayId,
    this.itemText,
    this.itemIsDeleted
  });
}

class ItemAddParamModel {
  final int itemDayId;
  final String itemText;

  ItemAddParamModel({
    required this.itemDayId,
    required this.itemText,
  });
}

class ItemUpdateParamModel {
  final int whereItemId;
  final int? itemDayId;
  final String? itemText;

  ItemUpdateParamModel({
    required this.whereItemId,
    this.itemDayId,
    this.itemText,
  });
}

class ItemDeleteParamModel {
  final int itemId;

  ItemDeleteParamModel({
    required this.itemId
  });
}