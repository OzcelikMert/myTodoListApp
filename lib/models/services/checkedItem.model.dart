import 'package:my_todo_list_app/config/db/tables/checkedItem.dart';
import 'package:my_todo_list_app/config/db/tables/item.dart';

class CheckedItemGetResultModel {
  final int checkedItemId;
  final int checkedItemItemId;
  final String checkedItemCreatedAt;
  final String checkedItemUpdatedAt;

  CheckedItemGetResultModel(
      {
      required this.checkedItemId,
      required this.checkedItemItemId,
      required this.checkedItemCreatedAt,
      required this.checkedItemUpdatedAt});

  Map<String, dynamic> toJson() {
    return {
      DBTableCheckedItems.columnId: checkedItemId,
      DBTableCheckedItems.columnItemId: checkedItemItemId,
      DBTableCheckedItems.columnCreatedAt: checkedItemCreatedAt,
      DBTableCheckedItems.columnUpdatedAt: checkedItemUpdatedAt,
    };
  }

  static CheckedItemGetResultModel fromJson(Map<String, dynamic> json) {
    return CheckedItemGetResultModel(
      checkedItemId:
          int.tryParse(json[DBTableCheckedItems.columnId].toString()) ?? 0,
      checkedItemItemId:
          int.tryParse(json[DBTableCheckedItems.columnItemId].toString()) ?? 0,
      checkedItemCreatedAt:
          json[DBTableCheckedItems.columnCreatedAt].toString(),
      checkedItemUpdatedAt:
          json[DBTableCheckedItems.columnUpdatedAt].toString(),
    );
  }
}

class CheckedItemGetParamModel {
  final int? checkedItemId;
  final int? checkedItemItemId;
  final String? checkedItemCreatedAt;

  CheckedItemGetParamModel(
      {this.checkedItemId, this.checkedItemCreatedAt, this.checkedItemItemId});
}

class CheckedItemAddParamModel {
  final int checkedItemItemId;

  CheckedItemAddParamModel({
    required this.checkedItemItemId,
  });
}

class CheckedItemDeleteParamModel {
  final int? checkedItemId;
  final int? checkedItemItemId;

  CheckedItemDeleteParamModel({this.checkedItemId, this.checkedItemItemId});
}
