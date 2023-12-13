import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_todo_list_app/components/elements/dataTable/index.dart';
import 'package:my_todo_list_app/config/db/tables/checkedItem.dart';
import 'package:my_todo_list_app/config/db/tables/item.dart';
import 'package:my_todo_list_app/constants/dayId.const.dart';
import 'package:my_todo_list_app/constants/page.const.dart';
import 'package:my_todo_list_app/constants/theme.const.dart';
import 'package:my_todo_list_app/lib/dialog.lib.dart';
import 'package:my_todo_list_app/lib/provider.lib.dart';
import 'package:my_todo_list_app/lib/route.lib.dart';
import 'package:my_todo_list_app/models/components/elements/dataTable/dataCell.model.dart';
import 'package:my_todo_list_app/models/components/elements/dataTable/dataColumn.model.dart';
import 'package:my_todo_list_app/models/components/elements/dialog/options.model.dart';
import 'package:my_todo_list_app/models/providers/page.provider.model.dart';
import 'package:my_todo_list_app/models/services/checkedItem.model.dart';
import 'package:my_todo_list_app/models/services/item.model.dart';
import 'package:my_todo_list_app/myLib/variable/array.dart';
import 'package:my_todo_list_app/services/checkedItem.service.dart';
import 'package:my_todo_list_app/services/item.service.dart';

import '../components/elements/button.dart';

class PageHome extends StatefulWidget {
  final BuildContext context;

  const PageHome({Key? key, required this.context}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  late List<ItemGetResultModel> _stateItems = [];
  late List<CheckedItemGetResultModel> _stateCheckedItems = [];
  late DateTime _stateDate = DateTime.now().toLocal();
  late bool _stateIsDateNow = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _pageInit();
    });
  }

  _pageInit() async {
    final pageProviderModel = ProviderLib.get<PageProviderModel>(context);
    pageProviderModel.setTitle("Yapılacaklar Listesi");

    await getItems();
    await getCheckedItems();

    pageProviderModel.setIsLoading(false);
  }

  Future<void> getItems() async {
    List<ItemGetResultModel> items = await ItemService.get(ItemGetParamModel());

    setState(() {
      _stateItems = MyLibArray.sort(
          array: items,
          key: DBTableItems.columnCreatedAt,
          sortType: SortType.desc);
    });
  }

  Future<void> getCheckedItems() async {
    List<CheckedItemGetResultModel> checkedItems = await CheckedItemService.get(CheckedItemGetParamModel(checkedItemCreatedAt: _stateDate.toUtc().toLocal().toString()));

    setState(() {
      _stateCheckedItems = MyLibArray.sort(
          array: checkedItems,
          key: DBTableCheckedItems.columnCreatedAt,
          sortType: SortType.desc);
    });
  }

  void onClickAddNew() async {
    await RouteLib.change(context: context, target: PageConst.routeNames.list);
  }

  void onClickChangeDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _stateDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: window.locale
    );

    if (pickedDate != null) {
      await DialogLib.show(
          context,
          ComponentDialogOptions(
              content: "Güncelleniyor...", icon: ComponentDialogIcon.loading));
      DateTime date = DateTime.now().toLocal();

      setState(() {
        _stateDate = pickedDate;
        _stateIsDateNow = DateTime(date.year, date.month, date.day)
            .isAtSameMomentAs(
                DateTime(pickedDate.year, pickedDate.month, pickedDate.day));
      });

      await getCheckedItems();

      DialogLib.hide(context);
    }
  }

  void onClickCheck(ItemGetResultModel row, bool isChecked) async {
    await DialogLib.show(
        context,
        ComponentDialogOptions(
            content: "Güncelleniyor...", icon: ComponentDialogIcon.loading));

    if (isChecked) {
      int result = await CheckedItemService.add(
          CheckedItemAddParamModel(checkedItemItemId: row.itemId));
      if (result > 0) {
        CheckedItemGetResultModel item = (await CheckedItemService.get(
            CheckedItemGetParamModel(checkedItemId: result)))[0];
        if(row.itemDayId == DayIdConst.aim){
          await ItemService.delete(ItemDeleteParamModel(itemId: row.itemId));
        }
        setState(() {
          _stateCheckedItems = [item, ..._stateCheckedItems];
          if(row.itemDayId == DayIdConst.aim){
            _stateItems = _stateItems.map((item)  {
              if(item.itemId == row.itemId){
                item.itemIsDeleted = 1;
              }
              return item;
            }).toList();
          }
        });
      }
    } else {
      int result = await CheckedItemService.delete(
          CheckedItemDeleteParamModel(checkedItemItemId: row.itemId));
      if (result > 0) {
        if(row.itemDayId == DayIdConst.aim){
          await ItemService.update(ItemUpdateParamModel(whereItemId: row.itemId, itemIsDeleted: 0));
        }
        setState(() {
          _stateCheckedItems = MyLibArray.findMulti(
              array: _stateCheckedItems,
              key: DBTableCheckedItems.columnItemId,
              value: row.itemId,
              isLike: false);
          if(row.itemDayId == DayIdConst.aim){
            _stateItems = _stateItems.map((item)  {
              if(item.itemId == row.itemId){
                item.itemIsDeleted = 0;
              }
              return item;
            }).toList();
          }
        });
      }
    }
    DialogLib.hide(context);
  }

  @override
  Widget build(BuildContext context) {
    final pageProviderModel =
        ProviderLib.get<PageProviderModel>(context, listen: true);

    List<ItemGetResultModel> itemList = [];

    if(_stateIsDateNow){
      itemList = _stateItems.where((item) => item.itemIsDeleted == 0 || (item.itemDayId == DayIdConst.aim && MyLibArray.findSingle(
          array: _stateCheckedItems,
          key: DBTableCheckedItems.columnItemId,
          value: item.itemId) !=
          null)).toList();
    }else {
      itemList = _stateItems.where((item) => MyLibArray.findSingle(
          array: _stateCheckedItems,
          key: DBTableCheckedItems.columnItemId,
          value: item.itemId) !=
          null).toList();
    }

    itemList = itemList.where((item) => [DayIdConst.all, DayIdConst.aim, _stateDate.weekday].contains(item.itemDayId)).toList();

    return pageProviderModel.isLoading
        ? Container()
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                      child: ComponentButton(
                    text: "Takvim",
                    onPressed: () => onClickChangeDate(),
                    bgColor: ThemeConst.colors.warning,
                  )),
                  Padding(padding: EdgeInsets.all(ThemeConst.paddings.md)),
                  Expanded(
                      child: ComponentButton(
                    text: "Yeni Ekle",
                    onPressed: () => onClickAddNew(),
                    bgColor: ThemeConst.colors.primary,
                  )),
                ],
              ),
              Padding(padding: EdgeInsets.all(ThemeConst.paddings.md)),
              Center(
                  child: Text(DateFormat("yyyy-MM-dd").format(_stateDate),
                      style: TextStyle(fontSize: ThemeConst.fontSizes.lg))),
              Center(
                  child: Text(DayIdConst.getIdText(_stateDate.weekday),
                      style: TextStyle(fontSize: ThemeConst.fontSizes.md))),
              Padding(padding: EdgeInsets.all(ThemeConst.paddings.md)),
              itemList.length == 0
                  ? Center(
                      child: Text("Yapılacak listesi hayallarim kadar boş 🙄.",
                          style: TextStyle(fontSize: ThemeConst.fontSizes.md)))
                  : ComponentDataTable<ItemGetResultModel>(
                      data: itemList,
                      selectedColor: ThemeConst.colors.info,
                      isSearchable: false,
                      bgColorRow: (row) {
                        if (MyLibArray.findSingle(
                                array: _stateCheckedItems,
                                key: DBTableCheckedItems.columnItemId,
                                value: row.itemId) !=
                            null) {
                          return ThemeConst.colors.success;
                        }
                        return null;
                      },
                      columns: const [
                        ComponentDataColumnModule(
                          title: "Yapıldı",
                        ),
                        ComponentDataColumnModule(
                            title: "Metin", minWidth: 200),
                      ],
                      cells: [
                        ComponentDataCellModule(
                          child: (row) => Checkbox(
                            checkColor: ThemeConst.colors.light,
                            fillColor: MaterialStateProperty.all(
                                ThemeConst.colors.primary),
                            onChanged: !_stateIsDateNow
                                ? null
                                : (bool? value) =>
                                    onClickCheck(row, value ?? false),
                            value: MyLibArray.findSingle(
                                    array: _stateCheckedItems,
                                    key: DBTableCheckedItems.columnItemId,
                                    value: row.itemId) !=
                                null,
                          ),
                        ),
                        ComponentDataCellModule(
                          child: (row) => Container(
                              constraints: BoxConstraints(minWidth: 200),
                              child: Text(row.itemText)),
                        ),
                      ],
                    )
            ],
          );
  }
}
