// lib/core/utils/military_labels.dart

abstract class MilitaryLabels {
  static const _ranks = <String, String>{
    'CADET': 'Курсант',
    'SOLDIER': 'Рядовий',
    'PRIVATE': 'Рядовий',
    'JUNIOR_SERGEANT': 'Молодший сержант',
    'SERGEANT': 'Сержант',
    'SENIOR_SERGEANT': 'Старший сержант',
    'MASTER_SERGEANT': 'Головний сержант',
    'ENSIGN': 'Прапорщик',
    'SENIOR_ENSIGN': 'Старший прапорщик',
    'JUNIOR_LIEUTENANT': 'Молодший лейтенант',
    'LIEUTENANT': 'Лейтенант',
    'SENIOR_LIEUTENANT': 'Старший лейтенант',
    'CAPTAIN': 'Капітан',
    'MAJOR': 'Майор',
    'LIEUTENANT_COLONEL': 'Підполковник',
    'COLONEL': 'Полковник',
    'MAJOR_GENERAL': 'Генерал-майор',
    'LIEUTENANT_GENERAL': 'Генерал-лейтенант',
    'GENERAL': 'Генерал',
  };

  // Matches server enum: entity/Position.java
  static const _positions = <String, String>{
    'CADET': 'Курсант',
    'LISTENER': 'Слухач',
    'JOURNALIST': 'Журналіст',
    'SQUAD_COMMANDER': 'Командир відділення',
    'GROUP_COMMANDER': 'Командир групи',
    'COMPANY_MASTER_SERGEANT': 'Старшина роти',
    'TEACHER': 'Викладач',
    'SENIOR_TEACHER': 'Старший викладач',
    'DOCENT': 'Доцент',
    'PROFESSOR': 'Професор',
    'DEPUTY_HEAD_OF_KAFEDRA': 'Заст. нач. кафедри',
    'HEAD_OF_KAFEDRA': 'Начальник кафедри',
    'HEAD_OF_FACULTY': 'Начальник факультету',
    'HEAD_OF_EDUCATION_DEPARTMENT': 'Нач. навч. відділу',
    'DEPUTY_HEAD_OF_EDUCATION_DEPARTMENT': 'Заст. нач. навч. відділу',
    'DEPUTY_HEAD_OF_INSTITUTE_FOR_ACADEMIC_WORK': 'Заст. нач. ін-ту з НР',
    'HEAD_OF_EDUCATION_QUALITY_CONTROL_DEPARTMENT': 'Нач. відділу контролю якості',
    'MASTER_OFFICER': 'Офіцер-вихователь',
    'DEPUTY_HEAD_OF_NV': 'Заст. нач. НВ',
    'SENIOR_ASSISTANT_HEAD_OF_NV': 'Ст. помічник нач. НВ',
    'ASSISTANT_HEAD_OF_NV': 'Помічник нач. НВ',
    'HEAD_OF_GOSDN': 'Нач. ГОСДН',
    'SENIOR_OFFICER_GOSDN': 'Ст. офіцер ГОСДН',
    'HEAD_OF_NM_OFFICE': 'Нач. НМВ',
    'METHODIST_NMK': 'Методист НМК',
    'DEPUTY_HEAD_OF_FACULTY_FOR_ACADEMIC_WORK': 'Заст. нач. фак. з НР',
    'HEAD_OF_ZYAODVO_DEPARTMENT': 'Нач. відділу ЗЯОДВО',
    'LEADING_RESEARCH_FELLOW': 'Пров. наук. співробітник',
    'SENIOR_RESEARCH_FELLOW': 'Ст. наук. співробітник',
    'SENIOR_ASSISTANT': 'Старший асистент',
    'HEAD_OF_TRAINING_COURSE': 'Нач. навч. курсу',
    'COURSE_OFFICER': 'Офіцер курсу',
    'HEAD_OF_INSTITUTE': 'Начальник інституту',
    'DEPUTY_HEAD_OF_INSTITUTE_FOR_LOGISTICS': 'Заст. нач. ін-ту з логістики',
  };

  // Matches server enum: entity/Speciality.java
  static const _specialities = <String, String>{
    'COMPUTER_SCIENCES': "Комп'ютерні науки",
    'CYBERSECURITY_AND_INFORMATION_PROTECTION': 'Кібербезпека та захист інформації',
    'INFORMATION_SYSTEMS_AND_TECHNOLOGIES': 'Інформаційні системи та технології',
    'ELECTRONICS_ELECTRONIC_COMMUNICATIONS_INSTRUMENTATION_AND_RADIO_ENGINEERING':
        'Електроніка та радіотехніка',
    'MILITARY_MANAGEMENT': 'Військове управління',
    'ARMAMENT_AND_MILITARY_EQUIPMENT': 'Озброєння та військова техніка',
  };

  // Matches server enum: entity/Attend.java → display code used in the journal grid
  // null / absent from map = present (no attendance record)
  static const _attendCodes = <String, String>{
    'DUTY':          'Н',   // Наряд
    'EXCUSED':       'Зв',  // Звільнення
    'BUSINESS_TRIP': 'К',   // Відрядження
    'INDIVIDUAL':    'ІЗ',  // Індивідуальні заняття
    'VACATION':      'В',   // Відпустка
    'SICK':          'Хв',  // Хворий
    'ABSENT':        'Х',   // Не з'явився
  };

  // Display code → server enum name (for POST /attends)
  static const _attendEnums = <String, String>{
    'Н':  'DUTY',
    'Зв': 'EXCUSED',
    'К':  'BUSINESS_TRIP',
    'ІЗ': 'INDIVIDUAL',
    'В':  'VACATION',
    'Хв': 'SICK',
    'Х':  'ABSENT',
  };

  static String rank(String? code) =>
      code == null ? '—' : _ranks[code] ?? _toReadable(code);

  static String position(String? code) =>
      code == null ? '—' : _positions[code] ?? _toReadable(code);

  static String speciality(String? code) =>
      code == null ? '—' : _specialities[code] ?? _toReadable(code);

  /// Converts server enum name → short display code shown in the journal grid.
  /// Returns null when there is no attendance record (= cadet is present).
  static String? attendCode(String? apiValue) =>
      apiValue == null ? null : _attendCodes[apiValue];

  /// Converts journal display code → server enum name for POST/PATCH /attends.
  /// Returns null for 'П' (present) — caller should delete the record.
  static String? attendEnum(String? displayCode) =>
      displayCode == null || displayCode == 'П'
          ? null
          : _attendEnums[displayCode];

  static String _toReadable(String code) =>
      code.split('_').map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
}
