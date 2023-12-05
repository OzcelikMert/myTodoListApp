import 'package:flutter/material.dart';
import 'package:my_todo_list_app/components/tools/page.dart';
import 'package:my_todo_list_app/constants/page.const.dart';
import 'package:my_todo_list_app/models/providers/page.provider.model.dart';
import 'package:my_todo_list_app/pages/listDetail.dart';
import 'package:my_todo_list_app/pages/settings.dart';
import 'package:my_todo_list_app/pages/home.dart';
import 'package:my_todo_list_app/pages/list.dart';

import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
      MultiProvider(
          providers: [],
          child: MyApp()
      )
  );
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'My Todo List App',
        theme: ThemeData.dark(),
        initialRoute: "/",
        onGenerateRoute: (settings) {
          var routeName = settings.name;
          Function(BuildContext context) returnPage = (context) {};

          if(routeName == PageConst.routeNames.home) {
            returnPage = (context) => PageHome(context: context);
          }else if(routeName == PageConst.routeNames.settings) {
            returnPage = (context) => PageSettings(context: context);
          }else if(routeName == PageConst.routeNames.list) {
            returnPage = (context) => PageList(context: context);
          }else if(routeName == PageConst.routeNames.listDetail) {
            returnPage = (context) => PageListDetail(context: context);
          }

          return MaterialPageRoute(builder: (context) => ChangeNotifierProvider<PageProviderModel>(
              create: (_) => PageProviderModel(),
              child: ComponentPage(child: returnPage(context)),
          ), settings: settings);
        });
  }
}
