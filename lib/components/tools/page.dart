import 'package:flutter/material.dart';
import 'package:my_todo_list_app/components/tools/preLoader.dart';
import 'package:my_todo_list_app/components/tools/sidebar.dart';
import 'package:my_todo_list_app/constants/page.const.dart';
import 'package:my_todo_list_app/constants/theme.const.dart';
import 'package:my_todo_list_app/lib/provider.lib.dart';
import 'package:my_todo_list_app/models/providers/page.provider.model.dart';
import 'package:provider/provider.dart';

class ComponentPage extends StatefulWidget {
  final Widget child;

  const ComponentPage({Key? key, required this.child}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComponentPageState();
}

class _ComponentPageState extends State<ComponentPage> {
  PreferredSizeWidget? _componentAppBar() {
    Widget _componentBackButton() {
      return BackButton(
        onPressed: () {
          final pageProviderModel = ProviderLib.get<PageProviderModel>(context);
          Navigator.of(context).pop(pageProviderModel.leadingArgs);
        },
      );
    }

    final pageProviderModel =
        ProviderLib.get<PageProviderModel>(context, listen: true);
    String? routeName = ModalRoute.of(context)?.settings.name;
    bool showBackButton = [PageConst.routeNames.listDetail].contains(routeName);
    bool hide = [].contains(routeName);

    return hide || pageProviderModel.isLoading
        ? null
        : AppBar(
            centerTitle: true,
            title: Consumer<PageProviderModel>(
              builder: (context, model, child) {
                return Text(model.title);
              },
            ),
            leading: Navigator.canPop(context) && showBackButton
                ? _componentBackButton()
                : null,
          );
  }

  Widget _componentBody() {
    return Container(
        padding: EdgeInsets.all(ThemeConst.paddings.md),
        child: widget.child
    );
  }

  Widget? _componentSidebar() {
    final pageProviderModel =
        ProviderLib.get<PageProviderModel>(context, listen: true);

    String? routeName = ModalRoute.of(context)?.settings.name;

    bool show = [
      PageConst.routeNames.home,
      PageConst.routeNames.list,
      PageConst.routeNames.settings
    ].contains(routeName);

    return show && !pageProviderModel.isLoading ? ComponentSideBar() : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _componentAppBar(),
        body: Stack(
          children: [
            ComponentPreLoader(),
            SingleChildScrollView(child:  _componentBody()),
          ],
        ),
        drawer: _componentSidebar(),
    );
  }
}
