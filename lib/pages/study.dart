import 'dart:math';
import 'package:flutter/material.dart';
import 'package:my_todo_list_app/components/elements/form.dart';
import 'package:my_todo_list_app/components/elements/iconButton.dart';
import 'package:my_todo_list_app/components/elements/progress.dart';
import 'package:my_todo_list_app/components/elements/radio.dart';
import 'package:my_todo_list_app/config/db/tables/words.dart';
import 'package:my_todo_list_app/constants/audio.const.dart';
import 'package:my_todo_list_app/constants/displayedLanguage.const.dart';
import 'package:my_todo_list_app/constants/page.const.dart';
import 'package:my_todo_list_app/constants/studyType.const.dart';
import 'package:my_todo_list_app/constants/theme.const.dart';
import 'package:my_todo_list_app/constants/wordType.const.dart';
import 'package:my_todo_list_app/lib/audio.lib.dart';
import 'package:my_todo_list_app/lib/dialog.lib.dart';
import 'package:my_todo_list_app/lib/provider.lib.dart';
import 'package:my_todo_list_app/lib/route.lib.dart';
import 'package:my_todo_list_app/lib/voices.lib.dart';
import 'package:my_todo_list_app/models/components/elements/dialog/options.model.dart';
import 'package:my_todo_list_app/models/providers/language.provider.model.dart';
import 'package:my_todo_list_app/models/providers/page.provider.model.dart';
import 'package:my_todo_list_app/models/services/word.model.dart';
import 'package:my_todo_list_app/myLib/variable/array.dart';
import 'package:my_todo_list_app/myLib/variable/string.dart';
import 'package:my_todo_list_app/services/word.service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../components/elements/button.dart';

class PageStudy extends StatefulWidget {
  late int studyType = 0;
  late int wordType = 0;
  final BuildContext context;

  PageStudy({Key? key, required this.context}) : super(key: key) {
    var args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null && args[DBTableWords.columnStudyType] != null) {
      studyType =
          int.tryParse(args[DBTableWords.columnStudyType].toString()) ?? 0;
      wordType = int.tryParse(args[DBTableWords.columnType].toString()) ?? 0;
    }
  }

  @override
  State<StatefulWidget> createState() => _PageStudyState();
}

class _PageStudyState extends State<PageStudy> {
  late bool _stateIsStudied = false;
  late bool _stateIsCorrect = false;
  late List<WordGetResultModel> _stateWords = [];
  late List<WordGetResultModel> _stateStudiedWords = [];
  late WordGetResultModel? _stateCurrentWord = null;
  late String _stateTextDisplayed = "";
  late String _stateTextAnswer = "";
  late bool _stateIsDisplayedTarget = false;
  final _controllerText = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _pageInit();
    });
  }

  _pageInit() async {
    if (widget.studyType == 0 || widget.wordType == 0) {
      await RouteLib.change(
          context: context, target: PageConst.routeNames.studyPlan);
      return;
    }
    final pageProviderModel = ProviderLib.get<PageProviderModel>(context);
    pageProviderModel.setTitle("Study");

    await VoicesLib.setVoiceSaved(context);

    final languageProviderModel =
        ProviderLib.get<LanguageProviderModel>(context);

    var words = await WordService.get(WordGetParamModel(
        wordLanguageId: languageProviderModel.selectedLanguage.languageId,
        wordStudyType: widget.studyType,
        wordType: widget.wordType));

    setState(() {
      _stateWords = MyLibArray.findMulti(
          array: words, key: DBTableWords.columnIsStudy, value: 0);
      _stateStudiedWords = MyLibArray.findMulti(
          array: words, key: DBTableWords.columnIsStudy, value: 1);
    });
    setCurrentWord();

    setTextDisplayedAndAnswer();

    pageProviderModel.setIsLoading(false);
  }

  setTextDisplayedAndAnswer({bool setTTS = true}) {
    final languageProviderModel =
        ProviderLib.get<LanguageProviderModel>(context);

    int displayedLanguage =
        languageProviderModel.selectedLanguage.languageDisplayedLanguage;

    bool isDisplayedTarget = false;

    if ([
      DisplayedLanguageConst.targetToNative,
      DisplayedLanguageConst.random,
      DisplayedLanguageConst.targetVoiceToNative,
      DisplayedLanguageConst.targetVoiceToTarget
    ].contains(displayedLanguage)) {
      isDisplayedTarget = true;

      if (displayedLanguage == DisplayedLanguageConst.random) {
        var random = Random();
        int randomNumber = random.nextInt(2);
        if (randomNumber == 0) {
          isDisplayedTarget = false;
        }
      }
    }

    setState(() {
      _stateTextDisplayed = isDisplayedTarget
          ? _stateCurrentWord!.wordTextTarget
          : _stateCurrentWord!.wordTextNative;
      _stateTextAnswer = isDisplayedTarget &&
              displayedLanguage != DisplayedLanguageConst.targetVoiceToTarget
          ? _stateCurrentWord!.wordTextNative
          : _stateCurrentWord!.wordTextTarget;
      _stateIsDisplayedTarget = isDisplayedTarget;
    });

    if (isDisplayedTarget &&
        languageProviderModel.selectedLanguage.languageIsAutoVoice == 1 &&
        setTTS == true) {
      onClickTTS();
    }
  }

  void setCurrentWord() {
    var random = Random();
    int randomNumber = random.nextInt(_stateWords.length);

    if (_stateCurrentWord != null &&
        _stateWords.length > 1 &&
        _stateWords[randomNumber].wordId == _stateCurrentWord!.wordId) {
      setCurrentWord();
      return;
    }

    setState(() {
      _stateCurrentWord = _stateWords[randomNumber];
      _stateIsCorrect = false;
      _stateIsStudied = false;
    });
  }

  void onClickCheck({correctStatus = null}) async {
    await DialogLib.show(
        context,
        ComponentDialogOptions(
            content: "Checking...", icon: ComponentDialogIcon.loading));

    setState(() {
      _stateIsStudied = true;
      _stateIsCorrect = correctStatus != null
          ? correctStatus
          : MyLibString.removePunctuation(
                  _stateTextAnswer.toString().toLowerCase()) ==
              MyLibString.removePunctuation(
                  _controllerText.text.toString().toLowerCase().trim());

      if (_stateIsCorrect == true &&
          MyLibArray.findSingle(
                  array: _stateStudiedWords,
                  key: DBTableWords.columnId,
                  value: _stateCurrentWord!.wordId) ==
              null) {
        _stateWords = MyLibArray.findMulti(
            array: _stateWords,
            key: DBTableWords.columnId,
            value: _stateCurrentWord!.wordId,
            isLike: false);
        _stateStudiedWords.add(_stateCurrentWord!);
      } else if (_stateIsCorrect == false &&
          MyLibArray.findSingle(
                  array: _stateWords,
                  key: DBTableWords.columnId,
                  value: _stateCurrentWord!.wordId) ==
              null) {
        _stateStudiedWords = MyLibArray.findMulti(
            array: _stateStudiedWords,
            key: DBTableWords.columnId,
            value: _stateCurrentWord!.wordId,
            isLike: false);
        _stateWords.add(_stateCurrentWord!);
      }
    });

    final languageProviderModel =
        ProviderLib.get<LanguageProviderModel>(context);

    if (_stateIsCorrect) {
      var updateWord = await WordService.update(WordUpdateParamModel(
          whereWordLanguageId:
              languageProviderModel.selectedLanguage.languageId,
          whereWordId: _stateCurrentWord!.wordId,
          wordIsStudy: 1));
      if (updateWord > 0) {
        if (languageProviderModel
                .selectedLanguage.languageIsActiveSuccessVoice ==
            1) {
          AudioLib.play(AudioConst.positive);
        }
        DialogLib.show(
            context,
            ComponentDialogOptions(
              title: "🤗 Correct! 🤗",
              content: "Congratulations your answer is correct! 🤗",
              icon: ComponentDialogIcon.success,
              onPressed: (isConfirm) async {
                if (isConfirm) {
                  if (_stateWords.isEmpty) {
                    AudioLib.play(AudioConst.positive_2);
                    DialogLib.show(
                        context,
                        ComponentDialogOptions(
                            title: "🤩 Finally Over! 🤩",
                            content:
                                "Congratulations, you have mastered all the words. 🤩",
                            icon: ComponentDialogIcon.success));
                    return false;
                  }
                }
              },
            ));
      } else {
        DialogLib.show(
            context,
            ComponentDialogOptions(
                content: "It' couldn't be update!",
                icon: ComponentDialogIcon.error));
      }
    } else {
      if (languageProviderModel.selectedLanguage.languageIsActiveSuccessVoice ==
          1) {
        AudioLib.play(AudioConst.negative);
      }
      DialogLib.show(
          context,
          ComponentDialogOptions(
              title: "😥 Wrong! 😥",
              content: "Unfortunately your answer is wrong! 😥",
              icon: ComponentDialogIcon.error));
    }
  }

  void onClickBack() async {
    if (_stateWords.length > 0) {
      DialogLib.show(
          context,
          ComponentDialogOptions(
              title: "Are you sure?",
              content: "You will go back, do you want to exit study page?",
              showCancelButton: true,
              icon: ComponentDialogIcon.confirm,
              onPressed: (bool isConfirm) async {
                if (isConfirm) {
                  await RouteLib.change(
                      context: context,
                      target: PageConst.routeNames.studyPlan,
                      arguments: {DBTableWords.columnType: widget.wordType});
                }
              }));
    } else {
      await RouteLib.change(
          context: context,
          target: PageConst.routeNames.studyPlan,
          arguments: {DBTableWords.columnType: widget.wordType});
    }
  }

  void onClickSettings() async {
    var isUpdated = await RouteLib.change(
        context: context,
        target: PageConst.routeNames.studySettings,
        safeHistory: true);
    if (isUpdated == true) {
      await DialogLib.show(
          context, ComponentDialogOptions(icon: ComponentDialogIcon.loading));
      setTextDisplayedAndAnswer();
      DialogLib.hide(context);
    }
  }

  void onClickNext() async {
    await DialogLib.show(
        context,
        ComponentDialogOptions(
            content: "Loading...", icon: ComponentDialogIcon.loading));

    setCurrentWord();
    setTextDisplayedAndAnswer();
    _controllerText.text = "";

    DialogLib.hide(context);
  }

  void onClickTTS() async {
    if (await Permission.speech.request() != PermissionStatus.granted) {
      return;
    }
    await (await VoicesLib.flutterTts).speak(
        _stateIsDisplayedTarget ? _stateTextDisplayed : _stateTextAnswer);
  }

  void onClickComment() async {
    DialogLib.show(
        context,
        ComponentDialogOptions(
            title: "🧐 Comment 🧐", content: _stateCurrentWord!.wordComment));
  }

  void onClickEdit() async {
    WordGetResultModel? updateData = await RouteLib.change(
        context: context,
        target: PageConst.routeNames.wordEdit,
        arguments: {DBTableWords.columnId: _stateCurrentWord!.wordId},
        safeHistory: true);
    if (updateData != null) {
      await DialogLib.show(
          context,
          ComponentDialogOptions(
              content: "Loading...", icon: ComponentDialogIcon.loading));

      setState(() {
        if (_stateIsCorrect) {
          _stateStudiedWords = _stateStudiedWords.map((word) {
            if (word.wordId == updateData.wordId) {
              word = updateData;
            }
            return word;
          }).toList();
        } else {
          _stateWords = _stateWords.map((word) {
            if (word.wordId == updateData.wordId) {
              word = updateData;
            }
            return word;
          }).toList();
        }
        _stateCurrentWord = updateData;
      });

      setTextDisplayedAndAnswer(setTTS: false);

      DialogLib.hide(context);
    }
  }

  void onClickChangeCorrectStatus({correctStatus = true}) async {
    DialogLib.show(
        context,
        ComponentDialogOptions(
          title: "🤔 Are you sure about that? 🤔",
          content:
              "Do you want to change this '${WordTypeConst.getTypeName(widget.wordType)}' status to '${correctStatus == true ? "Correct" : "Wrong"}'? 😶",
          showCancelButton: true,
          icon: ComponentDialogIcon.confirm,
          onPressed: (isConfirm) async {
            if (isConfirm) {
              onClickCheck(correctStatus: correctStatus);
              return false;
            }
          },
        ));
  }

  void onClickProgress() async {
    await RouteLib.change(
        context: context,
        target: PageConst.routeNames.wordListStudied,
        arguments: {
          DBTableWords.columnStudyType: widget.studyType,
          DBTableWords.columnType: widget.wordType
        },
        safeHistory: true);
  }

  String? onValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter some text';
    }
    return null;
  }

  Widget _componentAnswer() {
    return ComponentForm(
      formKey: _formKey,
      onSubmit: onClickCheck,
      submitButtonText: "Check",
      children: <Widget>[
        Consumer<LanguageProviderModel>(
          builder: (context, model, child) {
            return Text(!_stateIsDisplayedTarget
                ? model.selectedLanguage.languageName
                : "Native");
          },
        ),
        TextFormField(
            controller: _controllerText,
            validator: onValidator,
            decoration: const InputDecoration(
              hintText: '...',
            ))
      ],
    );
  }

  Widget _componentCorrectWord() {
    return Column(
      children: [
        Padding(padding: EdgeInsets.all(ThemeConst.paddings.sm)),
        Row(
          children: [
            Icon(Icons.check,
                size: ThemeConst.fontSizes.xlg,
                color: ThemeConst.colors.success),
            Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: ThemeConst.paddings.xsm)),
            Expanded(
                child: Text(
              _stateTextAnswer,
              style: TextStyle(
                fontSize: ThemeConst.fontSizes.md,
                color: ThemeConst.colors.success,
                fontWeight: FontWeight.bold,
              ),
            ))
          ],
        ),
      ],
    );
  }

  Widget _componentWrongWord() {
    return Column(
      children: [
        Padding(padding: EdgeInsets.all(ThemeConst.paddings.sm)),
        Row(
          children: [
            Icon(Icons.close,
                size: ThemeConst.fontSizes.xlg,
                color: ThemeConst.colors.danger),
            Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: ThemeConst.paddings.xsm)),
            Expanded(
                child: Text(
              _controllerText.text,
              style: TextStyle(
                fontSize: ThemeConst.fontSizes.md,
                color: ThemeConst.colors.danger,
                fontWeight: FontWeight.bold,
              ),
            ))
          ],
        ),
      ],
    );
  }

  Widget _componentInfo() {
    Widget _componentVoice() {
      return _stateIsDisplayedTarget || _stateIsStudied
          ? ComponentIconButton(
              onPressed: onClickTTS,
              icon: Icons.volume_up,
              color: ThemeConst.colors.info,
            )
          : Container();
    }

    Widget _componentComment() {
      return ComponentIconButton(
        onPressed: onClickComment,
        icon: Icons.lightbulb,
        color: ThemeConst.colors.success,
      );
    }

    Widget _componentEdit() {
      return ComponentIconButton(
        onPressed: onClickEdit,
        icon: Icons.edit,
        color: ThemeConst.colors.warning,
      );
    }

    Widget _componentPadding() {
      return Padding(
          padding: EdgeInsets.symmetric(horizontal: ThemeConst.paddings.sm));
    }

    List<Widget> children = [
      ...(_stateIsDisplayedTarget || _stateIsStudied
          ? [_componentVoice(), _componentPadding()]
          : []),
      ...(_stateCurrentWord!.wordComment.toString().isNotEmpty
          ? [_componentComment(), _componentPadding()]
          : []),
      ...(_stateIsStudied ? [_componentEdit(), _componentPadding()] : []),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children.length > 0
          ? children.sublist(0, children.length - 1)
          : children,
    );
  }

  Widget _componentProgress() {
    var totalWords = _stateWords.length + _stateStudiedWords.length;
    return Column(
      children: [
        GestureDetector(
          onTap: onClickProgress,
          child: Text(
            "$totalWords / ${_stateStudiedWords.length}",
            style: TextStyle(fontSize: ThemeConst.fontSizes.md),
          ),
        ),
        Padding(
            padding: EdgeInsets.symmetric(vertical: ThemeConst.paddings.sm)),
        ComponentProgress(
            maxValue: totalWords.toDouble(),
            currentValue: _stateStudiedWords.length.toDouble()),
      ],
    );
  }

  Widget _componentStatusMessage() {
    return Column(
      children: [
        Padding(
            padding: EdgeInsets.symmetric(vertical: ThemeConst.paddings.md)),
        Text(
          _stateIsCorrect ? "🤗 Correct! 🤗" : "😥 Wrong! 😥",
          style: TextStyle(
              fontSize: ThemeConst.fontSizes.md,
              color: _stateIsCorrect
                  ? ThemeConst.colors.success
                  : ThemeConst.colors.danger),
        ),
      ],
    );
  }

  Widget _componentNavbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          child: ComponentIconButton(
            onPressed: onClickBack,
            icon: Icons.arrow_back,
          ),
        ),
        Container(
            child: Text(
                "${StudyTypeConst.getTypeName(widget.studyType)} (${WordTypeConst.getTypeName(widget.wordType)})",
                style: TextStyle(fontSize: ThemeConst.fontSizes.md))),
        Container(
          child: ComponentIconButton(
              onPressed: onClickSettings, icon: Icons.settings),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProviderModel =
        ProviderLib.get<LanguageProviderModel>(context, listen: true);
    final pageProviderModel =
        ProviderLib.get<PageProviderModel>(context, listen: true);
    final selectedLanguage =
        languageProviderModel.selectedLanguage.languageDisplayedLanguage;

    return pageProviderModel.isLoading
        ? Container()
        : Column(
            children: <Widget>[
              Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: ThemeConst.paddings.md)),
              _componentNavbar(),
              Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: ThemeConst.paddings.sm)),
              _componentProgress(),
              Padding(padding: EdgeInsets.all(ThemeConst.paddings.xlg)),
              [
                        DisplayedLanguageConst.targetVoiceToNative,
                        DisplayedLanguageConst.targetVoiceToTarget
                      ].contains(selectedLanguage) &&
                      !_stateIsStudied
                  ? Container()
                  : Text(
                      _stateTextDisplayed,
                      style: TextStyle(fontSize: ThemeConst.fontSizes.lg),
                    ),
              Padding(padding: EdgeInsets.all(ThemeConst.paddings.sm)),
              _componentInfo(),
              _stateIsStudied ? _componentStatusMessage() : Container(),
              Padding(padding: EdgeInsets.all(ThemeConst.paddings.md)),
              !_stateIsStudied ? _componentAnswer() : Container(),
              _stateIsStudied && !_stateIsCorrect
                  ? _componentWrongWord()
                  : Container(),
              _stateIsStudied ? _componentCorrectWord() : Container(),
              Padding(padding: EdgeInsets.all(ThemeConst.paddings.md)),
              _stateIsStudied && _stateWords.isNotEmpty
                  ? ComponentButton(
                      text: "Next",
                      onPressed: onClickNext,
                      bgColor: ThemeConst.colors.success,
                    )
                  : Container(),
              Padding(padding: EdgeInsets.all(ThemeConst.paddings.sm)),
              _stateIsStudied
                  ? ComponentButton(
                      text: "Set `${_stateIsCorrect ? "Wrong" : "Correct"}`",
                      onPressed: () => onClickChangeCorrectStatus(
                          correctStatus: !_stateIsCorrect),
                      bgColor: _stateIsCorrect
                          ? ThemeConst.colors.danger
                          : ThemeConst.colors.warning,
                    )
                  : Container(),
            ],
          );
  }
}
