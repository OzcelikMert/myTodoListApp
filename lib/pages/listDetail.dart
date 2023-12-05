import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_todo_list_app/components/elements/dataTable/index.dart';
import 'package:my_todo_list_app/components/elements/form.dart';
import 'package:my_todo_list_app/components/elements/iconButton.dart';
import 'package:my_todo_list_app/config/db/tables/item.dart';
import 'package:my_todo_list_app/constants/page.const.dart';
import 'package:my_todo_list_app/constants/theme.const.dart';
import 'package:my_todo_list_app/lib/dialog.lib.dart';
import 'package:my_todo_list_app/lib/provider.lib.dart';
import 'package:my_todo_list_app/lib/route.lib.dart';
import 'package:my_todo_list_app/models/components/elements/dataTable/dataCell.model.dart';
import 'package:my_todo_list_app/models/components/elements/dataTable/dataColumn.model.dart';
import 'package:my_todo_list_app/models/components/elements/dialog/options.model.dart';
import 'package:my_todo_list_app/models/providers/page.provider.model.dart';
import 'package:my_todo_list_app/models/services/item.model.dart';
import 'package:my_todo_list_app/myLib/variable/array.dart';
import 'package:my_todo_list_app/services/item.service.dart';

class PageListDetail extends StatefulWidget {
  final BuildContext context;
  late int itemDayId = 0;

  PageListDetail({Key? key, required this.context}) : super(key: key) {
    var args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null && args[DBTableItems.columnId] != null) {
      itemDayId = int.tryParse(args[DBTableItems.columnId].toString()) ?? 0;
    }
  }

  @override
  State<StatefulWidget> createState() => _PageListDetailState();
}

class _PageListDetailState extends State<PageListDetail> {
  late List<ItemGetResultModel> _stateItems = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _controllerText = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _pageInit();
    });
  }

  _pageInit() async {
    if (widget.itemDayId == 0) {
      await RouteLib.change(
          context: context, target: PageConst.routeNames.list);
      return;
    }

    final pageProviderModel = ProviderLib.get<PageProviderModel>(context);

    await setPageTitle(pageProviderModel);

    await getDays();

    pageProviderModel.setIsLoading(false);
  }

  Future<void> setPageTitle(PageProviderModel pageProviderModel) async {
    pageProviderModel.setTitle("Todo Day List");
  }

  Future<void> getDays() async {
    List<ItemGetResultModel> items = await ItemService.get(ItemGetParamModel(
      itemDayId: widget.itemDayId,
      itemIsDeleted: 0,
    ));

    setState(() {
      _stateItems = MyLibArray.sort(
          array: items,
          key: DBTableItems.columnCreatedAt,
          sortType: SortType.desc);
    });
  }

  String? onValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen boş bırakmayınız!';
    }
    return null;
  }

  void onClickUpdate(ItemGetResultModel row) async {
    DialogLib.show(
        context,
        ComponentDialogOptions(
            title: "Devam etmek istiyor musun?",
            icon: ComponentDialogIcon.confirm,
            showCancelButton: true,
            content:
                "'${row.itemText}' maddesini '${_controllerText.text}' olarak güncellemek istediğinden emin misin?",
            onPressed: (bool isConfirm) async {
              if (isConfirm) {
                await DialogLib.show(
                    context,
                    ComponentDialogOptions(
                        content: "Güncelleniyor...",
                        icon: ComponentDialogIcon.loading));
                int result = await ItemService.update(ItemUpdateParamModel(
                    whereItemId: row.itemId,
                    itemText: _controllerText.text));
                if (result > 0) {
                  setState(() {
                    _stateItems = _stateItems.map((item) {
                        if(item.itemId == row.itemId){
                          item.itemText = _controllerText.text;
                        }
                        return item;
                    }).toList();
                  });
                  DialogLib.show(
                      context,
                      ComponentDialogOptions(
                          title: "İşlem Başarılı!",
                          content: "Başarı ile güncellendi!",
                          icon: ComponentDialogIcon.success));
                } else {
                  DialogLib.show(
                      context,
                      ComponentDialogOptions(
                          content: "Bir sorun oluştu! Lütfen desteğe bildiriniz.!",
                          icon: ComponentDialogIcon.error));
                }
                return false;
              }
            }));
  }

  void onClickEdit(ItemGetResultModel row) async {
    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Yapılacak Maddesi Düzenle'),
                  Padding(padding: EdgeInsets.all(ThemeConst.paddings.md)),
                  ComponentForm(
                      formKey: _formKey,
                      onSubmit: () => onClickUpdate(row),
                      submitButtonText: "Güncelle",
                      children: <Widget>[
                        const Text("Comment"),
                        TextFormField(
                          decoration: const InputDecoration(
                            hintText: '...',
                          ),
                          controller: _controllerText,
                          validator: onValidator,
                        ),
                      ]),
                  ElevatedButton(
                    child: const Text('Close BottomSheet'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        });
  }

  void onClickDelete(ItemGetResultModel row) {
    DialogLib.show(
        context,
        ComponentDialogOptions(
            title: "Devam etmek istiyor musun?",
            content:
                "'${row.itemText}' maddesini yapılacaklar listesinden silmek istediğinden emin misin?",
            cancelButtonText: "Hayır",
            confirmButtonText: "Evet",
            icon: ComponentDialogIcon.confirm,
            showCancelButton: true,
            onPressed: (bool isConfirm) async {
              if (isConfirm) {
                await DialogLib.show(
                    context,
                    ComponentDialogOptions(
                        content: "Siliniyor...",
                        icon: ComponentDialogIcon.loading));
                var result = await ItemService.delete(
                    ItemDeleteParamModel(itemId: row.itemId));
                if (result > 0) {
                  setState(() {
                    _stateItems = MyLibArray.findMulti(
                        array: _stateItems,
                        key: DBTableItems.columnId,
                        value: row.itemId,
                        isLike: false);
                  });
                  DialogLib.show(
                      context,
                      ComponentDialogOptions(
                          content:
                              "'${row.itemText}' maddesi yapılacaklar listesinden başarıyla silindi!",
                          icon: ComponentDialogIcon.success));
                } else {
                  DialogLib.show(
                      context,
                      ComponentDialogOptions(
                          content:
                              "Bir sorun oluştu! Lütfen desteğe bildiriniz.",
                          icon: ComponentDialogIcon.error));
                }
                return false;
              }
            }));
  }

  @override
  Widget build(BuildContext context) {
    final pageProviderModel =
        ProviderLib.get<PageProviderModel>(context, listen: true);

    return pageProviderModel.isLoading
        ? Container()
        : Column(
            children: [
              ComponentDataTable<ItemGetResultModel>(
                data: _stateItems,
                selectedColor: ThemeConst.colors.info,
                isSearchable: false,
                columns: const [
                  ComponentDataColumnModule(
                    title: "Metin",
                  ),
                  ComponentDataColumnModule(
                    title: "Düzenle",
                  ),
                  ComponentDataColumnModule(
                    title: "Sil",
                  ),
                ],
                cells: [
                  ComponentDataCellModule(
                    child: (row) => Text(row.itemText),
                  ),
                  ComponentDataCellModule(
                    child: (row) => ComponentIconButton(
                      onPressed: () => onClickEdit(row),
                      color: ThemeConst.colors.warning,
                      icon: Icons.edit,
                    ),
                  ),
                  ComponentDataCellModule(
                    child: (row) => ComponentIconButton(
                      onPressed: () => onClickDelete(row),
                      color: ThemeConst.colors.danger,
                      icon: Icons.edit,
                    ),
                  ),
                ],
              )
            ],
          );
  }
}
