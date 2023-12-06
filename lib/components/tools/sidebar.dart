import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_todo_list_app/constants/page.const.dart';
import 'package:my_todo_list_app/constants/theme.const.dart';
import 'package:my_todo_list_app/lib/dialog.lib.dart';
import 'package:my_todo_list_app/lib/file.lib.dart';
import 'package:my_todo_list_app/lib/provider.lib.dart';
import 'package:my_todo_list_app/lib/route.lib.dart';
import 'package:my_todo_list_app/models/components/elements/dialog/options.model.dart';
import 'package:my_todo_list_app/models/lib/file.lib.model.dart';
import 'package:my_todo_list_app/models/providers/page.provider.model.dart';
import 'package:my_todo_list_app/models/services/checkedItem.model.dart';
import 'package:my_todo_list_app/models/services/item.model.dart';
import 'package:my_todo_list_app/services/checkedItem.service.dart';
import 'package:my_todo_list_app/services/item.service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ComponentSideBar extends StatefulWidget {
  const ComponentSideBar({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComponentSideBarState();
}

class _ComponentSideBarState extends State<ComponentSideBar> {
  @override
  void initState() {
    super.initState();
  }

  Color? getActiveBG(String? routeName, String itemRouteName) {
    return routeName == itemRouteName ? ThemeConst.colors.dark : null;
  }

  Future<bool> checkFilePermission() async {
    bool returnStatus = false;
    final permissionStatus = await FileLib.checkPermission();
    if (permissionStatus.isGranted) {
      returnStatus = true;
    } else {
      if (await Permission.storage.shouldShowRequestRationale) {
        DialogLib.show(
            context,
            ComponentDialogOptions(
                title: "Permission Denied!",
                content: "You must give permission to perform file operations.",
                icon: ComponentDialogIcon.error));
      } else {
        DialogLib.show(
            context,
            ComponentDialogOptions(
              title: "Permission is permanently Denied!",
              content: "You must give permission to perform file operations.",
              icon: ComponentDialogIcon.error,
              showCancelButton: true,
              onPressed: (isConfirm) async {
                if (isConfirm) {
                  openAppSettings();
                }
              },
            ));
      }
    }
    return returnStatus;
  }

  void onClickExport() async {
    if (await checkFilePermission()) {
      DialogLib.show(
          context,
          ComponentDialogOptions(
              title: "Devam etmek istediğinden emin misin?",
              content: "Tüm yapılanları ve yapılacak listesini dışarı aktarmak istediğinden emin misin?",
              confirmButtonText: "Evet",
              cancelButtonText: "Hayır",
              showCancelButton: true,
              icon: ComponentDialogIcon.confirm,
              onPressed: (bool isConfirm) async {
                if (isConfirm) {
                  await DialogLib.show(
                      context,
                      ComponentDialogOptions(
                          content: "Dışa aktarılıyor...",
                          icon: ComponentDialogIcon.loading));
                  var items = await ItemService.get(ItemGetParamModel());
                  var checkedItems = await CheckedItemService.get(CheckedItemGetParamModel());
                  File? file = await FileLib.exportJsonFile(
                      fileName: "MyTodoListApp-${DateFormat("yyyy-MM-dd-HH-mm").format(DateTime.now().toLocal())}",
                      jsonString: jsonEncode(ExportJsonFileModel(items: items, checkedItems: checkedItems).toJson()));
                  if (file != null) {
                    DialogLib.show(
                        context,
                        ComponentDialogOptions(
                          title: "Başarılı!",
                          content:
                              "Dosya başarı ile dışarı aktarıldı. Lütfen indirilenler klasörünüzü kontrol ediniz.",
                          icon: ComponentDialogIcon.success,
                        ));
                  } else {
                    DialogLib.show(
                        context,
                        ComponentDialogOptions(
                            title: "Hata!",
                            content: "Bir sorun oluştu! Lütfen desteğe bildiriniz!",
                            icon: ComponentDialogIcon.error));
                  }
                  return false;
                }
              }));
    }
  }

  void onClickImport() async {
    var importedDataList = await FileLib.importJsonFile();
    if (importedDataList != null) {
      await DialogLib.show(
          context,
          ComponentDialogOptions(
              content: "İçe aktarılıyor...", icon: ComponentDialogIcon.loading));

      ImportJsonFileModel importJsonFileModel = ImportJsonFileModel.fromJson(importedDataList);
      if(importJsonFileModel.items != null){
        List<ItemAddParamModel> itemAddParams = [];
        for (var jsonItem in importJsonFileModel.items) {
          var item = ItemGetResultModel.fromJson(jsonItem);
          itemAddParams.add(ItemAddParamModel(
              itemDayId: item.itemDayId,
              itemText: item.itemText
          ));
        }
        await ItemService.addMulti(itemAddParams);
      }

      if(importJsonFileModel.checkedItems != null){
        List<CheckedItemAddParamModel> checkedItemAddParams = [];
        for (var jsonCheckedItem in importJsonFileModel.checkedItems) {
          var checkedItem = CheckedItemGetResultModel.fromJson(jsonCheckedItem);
          checkedItemAddParams.add(CheckedItemAddParamModel(
              checkedItemItemId: checkedItem.checkedItemItemId
          ));
        }
        await CheckedItemService.addMulti(checkedItemAddParams);
      }

      DialogLib.show(
          context,
          ComponentDialogOptions(
            title: "İşlem Başarılı!",
            content: "Dosya başarı ile içe aktarıldı.",
            icon: ComponentDialogIcon.success,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeName = ModalRoute.of(context)?.settings.name;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: ThemeConst.colors.primary,
            ),
            child: Center(child: Consumer<PageProviderModel>(
              builder: (context, model, child) {
                return Text(model.title);
              },
            )),
          ),
          Container(
            color: getActiveBG(routeName, PageConst.routeNames.home),
            child: ListTile(
              leading: const Icon(Icons.playlist_add_check),
              title: const Text('Bugün Yapılacaklar'),
              onTap: () async {
                await RouteLib.change(context: context, target: PageConst.routeNames.home);
              },
            ),
          ),
          Container(
            color: getActiveBG(routeName, PageConst.routeNames.list),
            child: ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Yapılacak Ekle'),
              onTap: () async {
                await RouteLib.change(context: context, target: PageConst.routeNames.list);
              },
            ),
          ),
          Container(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Dışa Aktar'),
              onTap: () => onClickExport(),
            ),
          ),
          Container(
            child: ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('İçe Aktar'),
              onTap: () => onClickImport(),
            ),
          ),
        ],
      ),
    );
  }
}
