import 'package:flutter/material.dart';
import 'package:my_todo_list_app/components/elements/dataTable/index.dart';
import 'package:my_todo_list_app/components/elements/iconButton.dart';
import 'package:my_todo_list_app/config/db/tables/item.dart';
import 'package:my_todo_list_app/constants/dayId.const.dart';
import 'package:my_todo_list_app/constants/page.const.dart';
import 'package:my_todo_list_app/constants/theme.const.dart';
import 'package:my_todo_list_app/lib/provider.lib.dart';
import 'package:my_todo_list_app/lib/route.lib.dart';
import 'package:my_todo_list_app/models/components/elements/dataTable/dataCell.model.dart';
import 'package:my_todo_list_app/models/components/elements/dataTable/dataColumn.model.dart';
import 'package:my_todo_list_app/models/providers/page.provider.model.dart';

class PageList extends StatefulWidget {
  final BuildContext context;

  const PageList({Key? key, required this.context}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PageListState();
}

class _PageListState extends State<PageList> {
  late List<int> _stateDays = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _pageInit();
    });
  }

  _pageInit() async {
    final pageProviderModel = ProviderLib.get<PageProviderModel>(context);
    pageProviderModel.setTitle("Yapılacaklar Gün Listesi");

    await getDays();

    pageProviderModel.setIsLoading(false);
  }

  Future<void> getDays() async {
    setState(() {
      _stateDays = [
        DayIdConst.all,
        DayIdConst.aim,
        DayIdConst.monday,
        DayIdConst.tuesday,
        DayIdConst.wednesday,
        DayIdConst.thursday,
        DayIdConst.friday,
        DayIdConst.saturday,
        DayIdConst.sunday
      ];
    });
  }

  void onClickEdit(int id) async {
    var updateData = await RouteLib.change(
        context: context,
        target: PageConst.routeNames.listDetail,
        arguments: {DBTableItems.columnDayId: id},
        safeHistory: true);
  }

  @override
  Widget build(BuildContext context) {
    final pageProviderModel =
        ProviderLib.get<PageProviderModel>(context, listen: true);

    return pageProviderModel.isLoading
        ? Container()
        : Column(
            children: [
              ComponentDataTable<int>(
                data: _stateDays,
                selectedColor: ThemeConst.colors.info,
                isSearchable: false,
                columns: const [
                  ComponentDataColumnModule(
                    title: "Gün",
                  ),
                  ComponentDataColumnModule(
                    title: "Düzenle",
                  ),
                ],
                cells: [
                  ComponentDataCellModule(
                    child: (row) => Container(constraints: BoxConstraints(minWidth: 150), child: Text(DayIdConst.getIdText(row))),
                  ),
                  ComponentDataCellModule(
                    child: (row) => ComponentIconButton(
                      onPressed: () => onClickEdit(row),
                      color: ThemeConst.colors.warning,
                      icon: Icons.edit,
                    ),
                  ),
                ],
              )
            ],
          );
  }
}
