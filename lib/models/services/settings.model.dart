class SettingsGetResultModel  {
  final String serviceInitHour;
  final bool serviceIsActive;

  const SettingsGetResultModel({required this.serviceInitHour, required this.serviceIsActive});
}

class SettingsUpdateParamModel  {
  final String? serviceInitHour;
  final bool? serviceIsActive;

  const SettingsUpdateParamModel({this.serviceInitHour, this.serviceIsActive});
}