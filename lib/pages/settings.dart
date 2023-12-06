import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_todo_list_app/components/elements/form.dart';
import 'package:my_todo_list_app/components/elements/radio.dart';
import 'package:my_todo_list_app/constants/theme.const.dart';
import 'package:my_todo_list_app/lib/dialog.lib.dart';
import 'package:my_todo_list_app/lib/provider.lib.dart';
import 'package:my_todo_list_app/models/components/elements/dialog/options.model.dart';
import 'package:my_todo_list_app/models/providers/page.provider.model.dart';
import 'package:my_todo_list_app/models/services/settings.model.dart';
import 'package:my_todo_list_app/services/settings.service.dart';

class PageSettings extends StatefulWidget {
  final BuildContext context;

  const PageSettings({Key? key, required this.context}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PageSettingsState();
}

class _PageSettingsState extends State<PageSettings> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late bool _stateServiceIsActive = false;
  final _controllerServiceInitHours = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _pageInit();
    });
  }

  _pageInit() async {
    final pageProviderModel = ProviderLib.get<PageProviderModel>(context);
    pageProviderModel.setTitle("Ayarlar");

    pageProviderModel.setIsLoading(false);
  }

  Future<void> getSettings() async {
    SettingsGetResultModel settings = await SettingsService.get();

    setState(() {
      _stateServiceIsActive = settings.serviceIsActive;
      _controllerServiceInitHours.text = settings.serviceInitHour;
    });
  }

  void onClickSave() async {
    await DialogLib.show(
        context,
        ComponentDialogOptions(
            content: "Güncelleniyor...", icon: ComponentDialogIcon.loading));

    bool result = await SettingsService.update(SettingsUpdateParamModel(
      serviceInitHour: _controllerServiceInitHours.text,
      serviceIsActive: _stateServiceIsActive
    ));

    if(result){
      DialogLib.show(
          context,
          ComponentDialogOptions(
              title: "İşlem Başarılı!",
              content: "Başarı ile güncellendi!",
              icon: ComponentDialogIcon.success));
    }else {
      DialogLib.show(
          context,
          ComponentDialogOptions(
              content: "Bir sorun oluştu! Lütfen desteğe bildiriniz.!",
              icon: ComponentDialogIcon.error));
    }
  }

  void onChangeServiceIsActive(bool? value) {
    if (value != null) {
      setState(() {
        _stateServiceIsActive = value;
      });
    }
  }

  String? onValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen boş bırakmayınız!';
    }
    return null;
  }

  Widget _componentServiceInitHour() {
    return Column(
      children: [
        Padding(padding: EdgeInsets.symmetric(vertical: ThemeConst.paddings.md)),
        const Text("Language Code"),
        TextFormField(
          decoration: const InputDecoration(
            hintText: 'Saat giriniz (Örn: 04:00)',
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-2][0-9]:[0-5][0-9]')),
            LengthLimitingTextInputFormatter(5),
          ],
          controller: _controllerServiceInitHours,
          validator: onValidator,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageProviderModel =
        ProviderLib.get<PageProviderModel>(context, listen: true);

    return pageProviderModel.isLoading
        ? Container()
        : Center(
            child: ComponentForm(
              formKey: _formKey,
              onSubmit: () => onClickSave(),
              submitButtonText: "Kaydet",
              children: <Widget>[
                const Text("Uyarı Mesajı"),
                ComponentRadio<bool>(
                  title: "Aktif",
                  value: true,
                  groupValue: _stateServiceIsActive,
                  onChanged: onChangeServiceIsActive,
                ),
                ComponentRadio<bool>(
                  title: 'Kapalı',
                  value: false,
                  groupValue: _stateServiceIsActive,
                  onChanged: onChangeServiceIsActive,
                ),
                _stateServiceIsActive ? _componentServiceInitHour() : Container()
              ],
            ),
          );
  }
}
