import 'package:flutter/material.dart';
import 'package:my_todo_list_app/components/elements/button.dart';
import 'package:my_todo_list_app/components/elements/dataTable/index.dart';
import 'package:my_todo_list_app/components/elements/form.dart';
import 'package:my_todo_list_app/components/elements/iconButton.dart';
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
import 'package:my_todo_list_app/models/services/item.model.dart';
import 'package:my_todo_list_app/myLib/variable/array.dart';
import 'package:my_todo_list_app/services/item.service.dart';

class PageListDetail extends StatefulWidget {
  final BuildContext context;
  late int itemDayId = 0;

  PageListDetail({Key? key, required this.context}) : super(key: key) {
    var args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null && args[DBTableItems.columnDayId] != null) {
      itemDayId = int.tryParse(args[DBTableItems.columnDayId].toString()) ?? 0;
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
    pageProviderModel.setTitle(
        "${DayIdConst.getIdText(widget.itemDayId)} Yapılacaklar Listesi");

    await getItems();

    pageProviderModel.setIsLoading(false);
  }

  Future<void> getItems() async {
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

  void onClickEdit(ItemGetResultModel row) async {
    DialogLib.show(
        context,
        ComponentDialogOptions(
            title: "Devam etmek istiyor musun?",
            icon: ComponentDialogIcon.confirm,
            showCancelButton: true,
            content:
                "'${row.itemText}' maddesini '${_controllerText.text}' olarak güncellemek istediğinden emin misin?",
            cancelButtonText: "Hayır",
            confirmButtonText: "Evet",
            onPressed: (bool isConfirm) async {
              if (isConfirm) {
                await DialogLib.show(
                    context,
                    ComponentDialogOptions(
                        content: "Güncelleniyor...",
                        icon: ComponentDialogIcon.loading));
                int result = await ItemService.update(ItemUpdateParamModel(
                    whereItemId: row.itemId, itemText: _controllerText.text));
                if (result > 0) {
                  setState(() {
                    _stateItems = _stateItems.map((item) {
                      if (item.itemId == row.itemId) {
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
                          content:
                              "Bir sorun oluştu! Lütfen desteğe bildiriniz.!",
                          icon: ComponentDialogIcon.error));
                }
                return false;
              }
            }));
  }

  void onClickAdd() async {
    await DialogLib.show(
        context,
        ComponentDialogOptions(
            content: "Ekleniyor...", icon: ComponentDialogIcon.loading));
    int result = await ItemService.add(ItemAddParamModel(
        itemDayId: widget.itemDayId, itemText: _controllerText.text));
    if (result > 0) {
      ItemGetResultModel item =
          (await ItemService.get(ItemGetParamModel(itemId: result)))[0];
      setState(() {
        _stateItems = [item, ..._stateItems];
      });
      _controllerText.text = "";
      DialogLib.show(
          context,
          ComponentDialogOptions(
              title: "İşlem Başarılı!",
              content: "Başarı ile eklendi!",
              icon: ComponentDialogIcon.success));
    } else {
      DialogLib.show(
          context,
          ComponentDialogOptions(
              content: "Bir sorun oluştu! Lütfen desteğe bildiriniz.!",
              icon: ComponentDialogIcon.error));
    }
  }

  void onClickAddModal({ItemGetResultModel? row}) async {
    _controllerText.text = row != null ? row.itemText : "";
    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
              height: 350,
              child: Padding(
                padding: EdgeInsets.all(ThemeConst.paddings.md),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Text(
                          'Yapılacak Maddesi ${row != null ? "Düzenle" : "Ekle"}', style: TextStyle(fontSize: ThemeConst.fontSizes.lg)),
                      Padding(padding: EdgeInsets.all(ThemeConst.paddings.md)),
                      ComponentForm(
                          formKey: _formKey,
                          onSubmit: () =>
                              row != null ? onClickEdit(row) : onClickAdd(),
                          submitButtonText: row != null ? "Güncelle" : "Ekle",
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
                    ],
                  ),
                ),
              ));
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                      child: ComponentButton(
                    text: "Yeni Ekle",
                    onPressed: () => onClickAddModal(),
                    bgColor: ThemeConst.colors.primary,
                  )),
                ],
              ),
              Padding(padding: EdgeInsets.all(ThemeConst.paddings.md)),
              ComponentDataTable<ItemGetResultModel>(
                data: _stateItems,
                selectedColor: ThemeConst.colors.info,
                isSearchable: false,
                columns: const [
                  ComponentDataColumnModule(title: "Metin", minWidth: 150),
                  ComponentDataColumnModule(
                    title: "Düzenle",
                  ),
                  ComponentDataColumnModule(
                    title: "Sil",
                  ),
                ],
                cells: [
                  ComponentDataCellModule(
                    child: (row) => Container(
                        constraints: BoxConstraints(minWidth: 150),
                        child: Text(row.itemText)),
                  ),
                  ComponentDataCellModule(
                    child: (row) => ComponentIconButton(
                      onPressed: () => onClickAddModal(row: row),
                      color: ThemeConst.colors.warning,
                      icon: Icons.edit,
                    ),
                  ),
                  ComponentDataCellModule(
                    child: (row) => ComponentIconButton(
                      onPressed: () => onClickDelete(row),
                      color: ThemeConst.colors.danger,
                      icon: Icons.delete,
                    ),
                  ),
                ],
              )
            ],
          );
  }
}
