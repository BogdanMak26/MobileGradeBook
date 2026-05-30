// lib/core/utils/military_labels.dart

abstract class MilitaryLabels {
  static const _ranks = <String, String>{
    'CADET':                  'Курсант',
    'CIVILIAN':               'Працівник ЗСУ',
    'SOLDIER':                'Солдат',
    'PRIVATE':                'Рядовий',
    'SENIOR_SOLDIER':         'Старший солдат',
    'JUNIOR_SERGEANT':        'Молодший сержант',
    'SERGEANT':               'Сержант',
    'SENIOR_SERGEANT':        'Старший сержант',
    'CHIEF_SERGEANT':         'Головний сержант',
    'STAFF_SERGEANT':         'Штаб-сержант',
    'MASTER_SERGEANT':        'Майстер-сержант',
    'SENIOR_MASTER_SERGEANT': 'Старший майстер-сержант',
    'CHIEF_MASTER_SERGEANT':  'Головний майстер-сержант',
    'ENSIGN':                 'Прапорщик',
    'SENIOR_ENSIGN':          'Старший прапорщик',
    'JUNIOR_LIEUTENANT':      'Молодший лейтенант',
    'LIEUTENANT':             'Лейтенант',
    'SENIOR_LIEUTENANT':      'Старший лейтенант',
    'CAPTAIN':                'Капітан',
    'MAJOR':                  'Майор',
    'LIEUTENANT_COLONEL':     'Підполковник',
    'COLONEL':                'Полковник',
    'BRIGADIER_GENERAL':      'Бригадний генерал',
    'MAJOR_GENERAL':          'Генерал-майор',
    'LIEUTENANT_GENERAL':     'Генерал-лейтенант',
    'GENERAL':                'Генерал',
  };

  // Matches server enum: entity/Position.java
  static const _positions = <String, String>{
    'CADET':                                         'Курсант',
    'LISTENER':                                      'Слухач',
    'JOURNALIST':                                    'Журналіст',
    'SQUAD_COMMANDER':                               'Командир відділення',
    'GROUP_COMMANDER':                               'Командир групи',
    'COMPANY_MASTER_SERGEANT':                       'Головний сержант курсу',
    'HEAD_OF_TRAINING_COURSE':                       'Начальник навчального курсу',
    'COURSE_OFFICER':                                'Курсовий офіцер',
    'SENIOR_ASSISTANT':                              'Старший помічник',
    'TEACHER':                                       'Викладач',
    'SENIOR_TEACHER':                                'Старший викладач',
    'DOCENT':                                        'Доцент',
    'PROFESSOR':                                     'Професор',
    'DEPUTY_HEAD_OF_KAFEDRA':                        'Заступник начальника кафедри',
    'HEAD_OF_KAFEDRA':                               'Начальник кафедри',
    'LEADING_RESEARCH_FELLOW':                       'Провідний науковий співробітник',
    'SENIOR_RESEARCH_FELLOW':                        'Старший науковий співробітник',
    'DEPUTY_HEAD_OF_FACULTY_FOR_ACADEMIC_WORK':      'Заступник начальника факультету з навчальної роботи',
    'HEAD_OF_FACULTY':                               'Начальник факультету',
    'DEPUTY_HEAD_OF_NV':                             'Заступник начальника НВ',
    'SENIOR_ASSISTANT_HEAD_OF_NV':                   'Ст. помічник начальника НВ',
    'ASSISTANT_HEAD_OF_NV':                          'Помічник начальника НВ',
    'DEPUTY_HEAD_OF_EDUCATION_DEPARTMENT':           'Заступник начальника навчального відділу',
    'HEAD_OF_EDUCATION_DEPARTMENT':                  'Начальник навчального відділу',
    'HEAD_OF_GOSDN':                                 'Начальник ГОСДН',
    'SENIOR_OFFICER_GOSDN':                          'Ст.офіцер ГОСДН',
    'HEAD_OF_NM_OFFICE':                             'Завідувач НМ кабінетом',
    'METHODIST_NMK':                                 'Методист НМК',
    'HEAD_OF_INSTITUTE':                             'Начальник інституту',
    'DEPUTY_HEAD_OF_INSTITUTE_FOR_ACADEMIC_WORK':    'Заступник начальника інституту з навчальної роботи',
    'DEPUTY_HEAD_OF_INSTITUTE_FOR_LOGISTICS':        'ЗНІ з логістики',
    'HEAD_OF_EDUCATION_QUALITY_CONTROL_DEPARTMENT':  'Начальник відділу контролю якості освіти',
    'HEAD_OF_ZYAODVO_DEPARTMENT':                    'Начальник відділу ЗЯОДВО',
    'MASTER_OFFICER':                                'Офіцер-вихователь',
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

  static String? rankCode(String? displayName) {
    if (displayName == null) return null;
    for (final e in _ranks.entries) {
      if (e.value == displayName) return e.key;
    }
    return null;
  }

  static String? positionCode(String? displayName) {
    if (displayName == null) return null;
    for (final e in _positions.entries) {
      if (e.value == displayName) return e.key;
    }
    return null;
  }

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
