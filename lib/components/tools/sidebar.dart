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
import 'package:my_todo_list_app/models/providers/page.provider.model.dart';
import 'package:my_todo_list_app/models/services/language.model.dart';
import 'package:my_todo_list_app/models/services/word.model.dart';
import 'package:my_todo_list_app/services/language.service.dart';
import 'package:my_todo_list_app/services/word.service.dart';
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

  void onClickReturnHome() async {
    await DialogLib.show(
        context, ComponentDialogOptions(icon: ComponentDialogIcon.loading));
    final languageProviderModel =
       ProviderLib.get<LanguageProviderModel>(context);

    var result = await LanguageService.update(LanguageUpdateParamModel(
        whereLanguageId:
            languageProviderModel.selectedLanguage.languageId,
        languageIsSelected: 0), context);
    if (result > 0) {
      await RouteLib.change(
          context: context, target: PageConst.routeNames.home);
    }
  }

  void onClickExport() async {
    if (await checkFilePermission()) {
      final languageProviderModel =
         ProviderLib.get<LanguageProviderModel>(context);

      DialogLib.show(
          context,
          ComponentDialogOptions(
              title: "Are you sure?",
              content: "Are you sure you want to export whole words?",
              showCancelButton: true,
              icon: ComponentDialogIcon.confirm,
              onPressed: (bool isConfirm) async {
                if (isConfirm) {
                  await DialogLib.show(
                      context,
                      ComponentDialogOptions(
                          content: "Loading...",
                          icon: ComponentDialogIcon.loading));
                  var words = await WordService.get(WordGetParamModel(
                      wordLanguageId: languageProviderModel
                          .selectedLanguage.languageId));
                  File? file = await FileLib.exportJsonFile(
                      fileName:
                          "LangApp-${languageProviderModel.selectedLanguage.languageName}-${DateFormat("yyyy-MM-dd-HH-mm").format(DateTime.now().toLocal())}",
                      jsonString: jsonEncode(words));
                  if (file != null) {
                    DialogLib.show(
                        context,
                        ComponentDialogOptions(
                          title: "Successfully!",
                          content:
                              "The file has saved successfully. Check your downloads folder.",
                          icon: ComponentDialogIcon.success,
                        ));
                  } else {
                    DialogLib.show(
                        context,
                        ComponentDialogOptions(
                            title: "Error!",
                            content: "It couldn't save.",
                            icon: ComponentDialogIcon.error));
                  }
                  return false;
                }
              }));
    }
  }

  void onClickImport() async {
    var importedDataList = await FileLib.importJsonFile();
    if (importedDataList != null &&
        importedDataList is List &&
        importedDataList.length > 0) {
      final languageProviderModel =
         ProviderLib.get<LanguageProviderModel>(context);

      await DialogLib.show(
          context,
          ComponentDialogOptions(
              content: "Loading...", icon: ComponentDialogIcon.loading));

      List<WordAddParamModel> wordAddParamsList = [];
      for (var importedData in importedDataList) {
        wordAddParamsList.add(WordAddParamModel(
            wordLanguageId: languageProviderModel
                .selectedLanguage.languageId,
            wordTextTarget: importedData[DBTableWords.columnTextTarget],
            wordTextNative: importedData[DBTableWords.columnTextNative],
            wordComment: importedData[DBTableWords.columnComment],
            wordStudyType: importedData[DBTableWords.columnStudyType],
            wordIsStudy: importedData[DBTableWords.columnIsStudy],
            wordType: importedData[DBTableWords.columnType] ?? WordTypeConst.word
        ));
      }
      int addWords = await WordService.addMulti(wordAddParamsList);
      if (addWords > 0) {
        DialogLib.show(
            context,
            ComponentDialogOptions(
              title: "Successfully!",
              content: "The file has imported successfully.",
              icon: ComponentDialogIcon.success,
            ));
      } else {
        DialogLib.show(
            context,
            ComponentDialogOptions(
                title: "Error!",
                content: "It couldn't import.",
                icon: ComponentDialogIcon.error));
      }
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
              title: const Text('Listeyi Dışa Aktar'),
              onTap: () => onClickExport(),
            ),
          ),
          Container(
            child: ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Listeyi İçe Aktar'),
              onTap: () => onClickImport(),
            ),
          ),
          Container(
            color: getActiveBG(routeName, PageConst.routeNames.settings),
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              onTap: () async {
                await RouteLib.change(context: context, target: PageConst.routeNames.settings);
              },
            ),
          ),
        ],
      ),
    );
  }
}
