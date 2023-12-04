import 'package:flutter/material.dart';
import 'package:my_todo_list_app/components/elements/button.dart';
import 'package:my_todo_list_app/components/pages/studyPlan/studyTypeButton.dart';
import 'package:my_todo_list_app/config/db/tables/words.dart';
import 'package:my_todo_list_app/constants/page.const.dart';
import 'package:my_todo_list_app/constants/studyType.const.dart';
import 'package:my_todo_list_app/constants/theme.const.dart';
import 'package:my_todo_list_app/constants/wordType.const.dart';
import 'package:my_todo_list_app/lib/dialog.lib.dart';
import 'package:my_todo_list_app/lib/provider.lib.dart';
import 'package:my_todo_list_app/lib/route.lib.dart';
import 'package:my_todo_list_app/models/components/elements/dialog/options.model.dart';
import 'package:my_todo_list_app/models/providers/language.provider.model.dart';
import 'package:my_todo_list_app/models/providers/page.provider.model.dart';
import 'package:my_todo_list_app/models/services/language.model.dart';
import 'package:my_todo_list_app/models/services/word.model.dart';
import 'package:my_todo_list_app/myLib/variable/array.dart';
import 'package:my_todo_list_app/services/language.service.dart';
import 'package:my_todo_list_app/services/word.service.dart';

class PageStudyPlan extends StatefulWidget {
  final BuildContext context;
  late int wordType = WordTypeConst.word;

  PageStudyPlan({Key? key, required this.context}) : super(key: key) {
    var args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null && args[DBTableWords.columnType] != null) {
      wordType = int.tryParse(args[DBTableWords.columnType].toString()) ?? 0;
    }
  }

  @override
  State<StatefulWidget> createState() => _PageStudyPlanState();
}

class _PageStudyPlanState extends State<PageStudyPlan> {
  late List<WordGetCountReportResultModel> _stateWordCountReports = [];
  late int _stateWordType = WordTypeConst.word;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _pageInit();
    });
  }

  _pageInit() async {
    final pageProviderModel = ProviderLib.get<PageProviderModel>(context);

    setState(() {
      _stateWordType =
          widget.wordType != 0 ? widget.wordType : WordTypeConst.word;
    });

    await setWordCountReports();
    await setPageTitle();

    pageProviderModel.setIsLoading(false);
  }

  Future<void> setPageTitle() async {
    final pageProviderModel = ProviderLib.get<PageProviderModel>(context);
    pageProviderModel
        .setTitle("Study Plan (${WordTypeConst.getTypeName(_stateWordType)})");
  }

  Future<void> setWordCountReports() async {
    final languageProviderModel =
        ProviderLib.get<LanguageProviderModel>(context);

    var wordCountReports = await WordService.getCountReport(
        WordGetCountReportParamModel(
            wordLanguageId: languageProviderModel.selectedLanguage.languageId,
            wordType: _stateWordType));

    setState(() {
      _stateWordCountReports = wordCountReports;
    });
  }

  void onClickStudy(int type) async {
    var reports = MyLibArray.findMulti(
        array: _stateWordCountReports,
        key: DBTableWords.columnStudyType,
        value: type);
    var unstudiedReports = MyLibArray.findMulti(
        array: reports, key: DBTableWords.columnIsStudy, value: 0);

    int totalWordCount = reports.isNotEmpty
        ? reports.map((e) => e.wordCount).reduce((a, b) => a + b)
        : 0;
    int unstudiedWordCount = unstudiedReports.isNotEmpty
        ? unstudiedReports.map((e) => e.wordCount).reduce((a, b) => a + b)
        : 0;

    if (totalWordCount == 0) {
      DialogLib.show(
          context,
          ComponentDialogOptions(
              content:
                  "There are no words. Please firstly you must add a word.",
              icon: ComponentDialogIcon.error));
    } else {
      DialogLib.show(
          context,
          ComponentDialogOptions(
              title: "Are you sure?",
              content:
                  "You have selected '${StudyTypeConst.getTypeName(type)}'. ${unstudiedWordCount == 0 ? "If you continue your all words in '${StudyTypeConst.getTypeName(type)}' will set is 'unstudied'." : ""} Are you sure you want to continue?",
              showCancelButton: true,
              icon: ComponentDialogIcon.confirm,
              onPressed: (bool isConfirm) async {
                if (isConfirm) {
                  await DialogLib.show(
                      context,
                      ComponentDialogOptions(
                          content: "Loading...",
                          icon: ComponentDialogIcon.loading));

                  final languageProviderModel =
                      ProviderLib.get<LanguageProviderModel>(context);

                  bool changeRoute = true;

                  if (unstudiedWordCount == 0) {
                    var wordUpdate = await WordService.update(
                        WordUpdateParamModel(
                            whereWordLanguageId: languageProviderModel
                                .selectedLanguage.languageId,
                            whereWordStudyType: type,
                            whereWordType: _stateWordType,
                            wordIsStudy: 0));
                    if (wordUpdate < 1) {
                      changeRoute = false;
                    }
                  }

                  var date = DateTime.now().toUtc().toString();
                  var languageUpdate = await LanguageService.update(
                      LanguageUpdateParamModel(
                        whereLanguageId:
                            languageProviderModel.selectedLanguage.languageId,
                        languageDailyWordUpdatedAt:
                            _stateWordType == WordTypeConst.word &&
                                    type == StudyTypeConst.daily
                                ? date
                                : null,
                        languageWeeklyWordUpdatedAt:
                            _stateWordType == WordTypeConst.word &&
                                    type == StudyTypeConst.weekly
                                ? date
                                : null,
                        languageMonthlyWordUpdatedAt:
                            _stateWordType == WordTypeConst.word &&
                                    type == StudyTypeConst.monthly
                                ? date
                                : null,
                        languageDailySentenceUpdatedAt:
                            _stateWordType == WordTypeConst.sentence &&
                                    type == StudyTypeConst.daily
                                ? date
                                : null,
                        languageWeeklySentenceUpdatedAt:
                            _stateWordType == WordTypeConst.sentence &&
                                    type == StudyTypeConst.weekly
                                ? date
                                : null,
                        languageMonthlySentenceUpdatedAt:
                            _stateWordType == WordTypeConst.sentence &&
                                    type == StudyTypeConst.monthly
                                ? date
                                : null,
                      ),
                      context);

                  if (languageUpdate < 1) {
                    changeRoute = false;
                  }

                  if (changeRoute) {
                    await RouteLib.change(
                        context: context,
                        target: PageConst.routeNames.study,
                        arguments: {
                          DBTableWords.columnStudyType: type,
                          DBTableWords.columnType: _stateWordType
                        });
                  } else {
                    DialogLib.show(
                        context,
                        ComponentDialogOptions(
                            content: "It couldn't continue!",
                            icon: ComponentDialogIcon.error));
                  }
                  return false;
                }
              }));
    }
  }

  void onClickRestart(int type) async {
    var reports = MyLibArray.findMulti(
        array: _stateWordCountReports,
        key: DBTableWords.columnStudyType,
        value: type);
    var unstudiedReports = MyLibArray.findMulti(
        array: reports, key: DBTableWords.columnIsStudy, value: 0);

    int totalWordCount = reports.isNotEmpty
        ? reports.map((e) => e.wordCount).reduce((a, b) => a + b)
        : 0;
    int unstudiedWordCount = unstudiedReports.isNotEmpty
        ? unstudiedReports.map((e) => e.wordCount).reduce((a, b) => a + b)
        : 0;

    if (totalWordCount == 0) {
      DialogLib.show(
          context,
          ComponentDialogOptions(
              content:
                  "There are no words. Please firstly you must add a word.",
              icon: ComponentDialogIcon.error));
    } else if (totalWordCount == unstudiedWordCount) {
      DialogLib.show(
          context,
          ComponentDialogOptions(
              content:
                  "There are no studied words. Please firstly you must study a word.",
              icon: ComponentDialogIcon.error));
    } else {
      DialogLib.show(
          context,
          ComponentDialogOptions(
              title: "Are you sure?",
              content:
                  "You have selected '${StudyTypeConst.getTypeName(type)}'. Are you sure you want to restart your progress?",
              showCancelButton: true,
              icon: ComponentDialogIcon.confirm,
              onPressed: (bool isConfirm) async {
                if (isConfirm) {
                  await DialogLib.show(
                      context,
                      ComponentDialogOptions(
                          content: "Loading...",
                          icon: ComponentDialogIcon.loading));

                  final languageProviderModel =
                      ProviderLib.get<LanguageProviderModel>(context);

                  var wordUpdate = await WordService.update(
                      WordUpdateParamModel(
                          whereWordLanguageId:
                              languageProviderModel.selectedLanguage.languageId,
                          whereWordStudyType: type,
                          whereWordType: _stateWordType,
                          wordIsStudy: 0));

                  if (wordUpdate > 0) {
                    await setWordCountReports();
                    DialogLib.show(
                        context,
                        ComponentDialogOptions(
                            content: "Restart is successful!",
                            icon: ComponentDialogIcon.success));
                  } else {
                    DialogLib.show(
                        context,
                        ComponentDialogOptions(
                            content: "It couldn't update!",
                            icon: ComponentDialogIcon.error));
                  }
                  return false;
                }
              }));
    }
  }

  Future<void> onClickChangeWordType(int type) async {
    if (type == _stateWordType) return;

    await DialogLib.show(
        context,
        ComponentDialogOptions(
            content: "Loading...", icon: ComponentDialogIcon.loading));

    setState(() {
      _stateWordType = type;
    });

    await setWordCountReports();
    await setPageTitle();

    DialogLib.hide(context);
  }

  Widget componentDaily() {
    final languageProviderModel =
        ProviderLib.get<LanguageProviderModel>(context, listen: true);
    var lastStudyDate = _stateWordType == WordTypeConst.word
        ? languageProviderModel.selectedLanguage.languageDailyWordUpdatedAt
        : languageProviderModel.selectedLanguage.languageDailySentenceUpdatedAt;
    var reports = MyLibArray.findMulti(
        array: _stateWordCountReports,
        key: DBTableWords.columnStudyType,
        value: StudyTypeConst.daily);
    var studiedReports = MyLibArray.findMulti(
        array: reports, key: DBTableWords.columnIsStudy, value: 1);
    var unstudiedReports = MyLibArray.findMulti(
        array: reports, key: DBTableWords.columnIsStudy, value: 0);

    return ComponentStudyTypeButton(
        bgColor: ThemeConst.colors.success,
        title: StudyTypeConst.getTypeName(StudyTypeConst.daily),
        onStartPressed: () => onClickStudy(StudyTypeConst.daily),
        onRestartPressed: () => onClickRestart(StudyTypeConst.daily),
        lastStudyDate: DateTime.parse(lastStudyDate.toString()),
        totalWords: reports.isNotEmpty
            ? reports.map((e) => e.wordCount).reduce((a, b) => a + b)
            : 0,
        studiedWords: studiedReports.isNotEmpty
            ? studiedReports.map((e) => e.wordCount).reduce((a, b) => a + b)
            : 0,
        unstudiedWords: unstudiedReports.isNotEmpty
            ? unstudiedReports.map((e) => e.wordCount).reduce((a, b) => a + b)
            : 0);
  }

  Widget componentWeekly() {
    final languageProviderModel =
        ProviderLib.get<LanguageProviderModel>(context, listen: true);
    var lastStudyDate = _stateWordType == WordTypeConst.word
        ? languageProviderModel.selectedLanguage.languageWeeklyWordUpdatedAt
        : languageProviderModel.selectedLanguage.languageWeeklySentenceUpdatedAt;
    var reports = MyLibArray.findMulti(
        array: _stateWordCountReports,
        key: DBTableWords.columnStudyType,
        value: StudyTypeConst.weekly);
    var studiedReports = MyLibArray.findMulti(
        array: reports, key: DBTableWords.columnIsStudy, value: 1);
    var unstudiedReports = MyLibArray.findMulti(
        array: reports, key: DBTableWords.columnIsStudy, value: 0);

    return ComponentStudyTypeButton(
        bgColor: ThemeConst.colors.danger,
        title: StudyTypeConst.getTypeName(StudyTypeConst.weekly),
        onStartPressed: () => onClickStudy(StudyTypeConst.weekly),
        onRestartPressed: () => onClickRestart(StudyTypeConst.weekly),
        lastStudyDate: DateTime.parse(lastStudyDate.toString()),
        totalWords: reports.isNotEmpty
            ? reports.map((e) => e.wordCount).reduce((a, b) => a + b)
            : 0,
        studiedWords: studiedReports.isNotEmpty
            ? studiedReports.map((e) => e.wordCount).reduce((a, b) => a + b)
            : 0,
        unstudiedWords: unstudiedReports.isNotEmpty
            ? unstudiedReports.map((e) => e.wordCount).reduce((a, b) => a + b)
            : 0);
  }

  Widget componentMonthly() {
    final languageProviderModel =
        ProviderLib.get<LanguageProviderModel>(context, listen: true);
    var lastStudyDate = _stateWordType == WordTypeConst.word
        ? languageProviderModel.selectedLanguage.languageMonthlyWordUpdatedAt
        : languageProviderModel.selectedLanguage.languageMonthlySentenceUpdatedAt;
    var reports = MyLibArray.findMulti(
        array: _stateWordCountReports,
        key: DBTableWords.columnStudyType,
        value: StudyTypeConst.monthly);
    var studiedReports = MyLibArray.findMulti(
        array: reports, key: DBTableWords.columnIsStudy, value: 1);
    var unstudiedReports = MyLibArray.findMulti(
        array: reports, key: DBTableWords.columnIsStudy, value: 0);

    return ComponentStudyTypeButton(
        bgColor: ThemeConst.colors.info,
        title: StudyTypeConst.getTypeName(StudyTypeConst.monthly),
        onStartPressed: () => onClickStudy(StudyTypeConst.monthly),
        onRestartPressed: () => onClickRestart(StudyTypeConst.monthly),
        lastStudyDate: DateTime.parse(lastStudyDate.toString()),
        totalWords: reports.isNotEmpty
            ? reports.map((e) => e.wordCount).reduce((a, b) => a + b)
            : 0,
        studiedWords: studiedReports.isNotEmpty
            ? studiedReports.map((e) => e.wordCount).reduce((a, b) => a + b)
            : 0,
        unstudiedWords: unstudiedReports.isNotEmpty
            ? unstudiedReports.map((e) => e.wordCount).reduce((a, b) => a + b)
            : 0);
  }

  @override
  Widget build(BuildContext context) {
    final pageProviderModel =
        ProviderLib.get<PageProviderModel>(context, listen: true);

    return pageProviderModel.isLoading
        ? Container()
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: ComponentButton(
                      text: WordTypeConst.getTypeName(WordTypeConst.word),
                      onPressed: () =>
                          onClickChangeWordType(WordTypeConst.word),
                      bgColor: _stateWordType == WordTypeConst.word
                          ? ThemeConst.colors.success
                          : null,
                    )),
                    Padding(padding: EdgeInsets.all(ThemeConst.paddings.md)),
                    Expanded(
                        child: ComponentButton(
                      text: WordTypeConst.getTypeName(WordTypeConst.sentence),
                      onPressed: () =>
                          onClickChangeWordType(WordTypeConst.sentence),
                      bgColor: _stateWordType == WordTypeConst.sentence
                          ? ThemeConst.colors.success
                          : null,
                    )),
                  ],
                ),
                Padding(padding: EdgeInsets.all(ThemeConst.paddings.sm)),
                componentDaily(),
                Padding(padding: EdgeInsets.all(ThemeConst.paddings.sm)),
                componentWeekly(),
                Padding(padding: EdgeInsets.all(ThemeConst.paddings.sm)),
                componentMonthly(),
              ],
            ),
          );
  }
}
