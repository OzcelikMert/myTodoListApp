import 'dart:convert';
import 'dart:developer';

import 'package:my_todo_list_app/config/db/tables/checkedItem.dart';
import 'package:my_todo_list_app/models/services/checkedItem.model.dart';
import 'package:my_todo_list_app/models/services/item.model.dart';

class ExportJsonFileModel  {
  final List<ItemGetResultModel> items;
  final List<CheckedItemGetResultModel> checkedItems;

  const ExportJsonFileModel({required this.items, required this.checkedItems});

  Map<String, dynamic> toJson() {
    return {
      "items": items,
      "checkedItems": checkedItems
    };
  }
}

class ImportJsonFileModel  {
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> checkedItems;

  const ImportJsonFileModel({required this.items, required this.checkedItems});

  static ImportJsonFileModel fromJson(Map<String, dynamic> json) {
    return ImportJsonFileModel(
        items: json["items"].cast<Map<String, dynamic>>(),
        checkedItems: json["checkedItems"].cast<Map<String, dynamic>>()
    );
  }
}