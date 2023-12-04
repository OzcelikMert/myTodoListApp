class DayIdConst {
  static const monday = 1;
  static const tuesday = 2;
  static const wednesday = 3;
  static const thursday = 4;
  static const friday = 5;
  static const saturday = 6;
  static const sunday = 7;

  static getIdName(int type) {
    String name = "";
    switch(type) {
      case DayIdConst.monday: name = "Pazartesi"; break;
      case DayIdConst.tuesday: name = "Salı"; break;
      case DayIdConst.wednesday: name = "Çarşamba"; break;
      case DayIdConst.thursday: name = "Perşembe"; break;
      case DayIdConst.friday: name = "Cuma"; break;
      case DayIdConst.saturday: name = "Cumartesi"; break;
      case DayIdConst.sunday: name = "Pazar"; break;
    }
    return name;
  }
}