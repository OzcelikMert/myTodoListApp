import 'package:my_todo_list_app/models/services/settings.model.dart';

class SettingsService {
  static Future<SettingsGetResultModel> get() async {
    return SettingsGetResultModel(serviceInitHour: "", serviceIsActive: false);
  }

  static Future<bool> update(SettingsUpdateParamModel params) async {
    return false;
  }
}
