// lib/shared/widgets/add_discipline_sheet.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Mock-дані (замінити на API-запит) ─────────────────────────────────────────

const _kafedrasMock = <Map<String, dynamic>>[
  {'id': 1,  'name': 'Кафедра №1',  'desc': 'Фундаментальних дисциплін'},
  {'id': 2,  'name': 'Кафедра №2',  'desc': 'Іноземних мов'},
  {'id': 3,  'name': 'Кафедра №3',  'desc': 'Автомобільної техніки'},
  {'id': 21, 'name': 'Кафедра №21', 'desc': 'Інформаційних систем та технологій'},
  {'id': 22, 'name': 'Кафедра №22', 'desc': "Комп'ютерних наук та інтелектуальних технологій"},
];

const _teachersByKafedra = <int, List<Map<String, dynamic>>>{
  1: [
    {'id': 1, 'name': 'Павленко Людмила'},
    {'id': 2, 'name': 'Горланов Сергій'},
    {'id': 3, 'name': 'Мисула Сергій'},
    {'id': 4, 'name': 'Федоренко Дарія'},
    {'id': 5, 'name': 'Кириленко Андрій'},
  ],
  2: [
    {'id': 6,  'name': 'Бондаренко Ольга'},
    {'id': 7,  'name': 'Ткаченко Наталія'},
    {'id': 8,  'name': 'Лисенко Марина'},
  ],
  3: [
    {'id': 9,  'name': 'Присяжний Василь'},
    {'id': 10, 'name': 'Мельник Ігор'},
    {'id': 11, 'name': 'Козаченко Роман'},
  ],
  21: [
    {'id': 12, 'name': 'Абламська Вікторія'},
    {'id': 13, 'name': 'Палагута Андрій'},
    {'id': 14, 'name': 'Левківський Роман'},
    {'id': 15, 'name': 'Сидоренко Петро'},
    {'id': 16, 'name': 'Гордієнко Тетяна'},
  ],
  22: [
    {'id': 17, 'name': 'Макаренко Богдан'},
    {'id': 18, 'name': 'Іваненко Василь'},
    {'id': 19, 'name': 'Петренко Сергій'},
    {'id': 20, 'name': 'Коваль Олег'},
    {'id': 21, 'name': 'Сачук Олексій'},
  ],
};

// ── Публічна функція для показу ───────────────────────────────────────────────

Future<void> showAddDisciplineSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddDisciplineSheet(),
  );
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

class AddDisciplineSheet extends StatefulWidget {
  const AddDisciplineSheet({super.key});

  @override
  State<AddDisciplineSheet> createState() => _AddDisciplineSheetState();
}

class _AddDisciplineSheetState extends State<AddDisciplineSheet> {
  final _formKey        = GlobalKey<FormState>();
  final _fullNameCtrl   = TextEditingController();
  final _shortNameCtrl  = TextEditingController();

  int?   _kafedraId;
  int?   _teacherId;
  String _teacherSearch = '';

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _shortNameCtrl.dispose();
    super.dispose();
  }

  // ── Стан форми ─────────────────────────────────────────────────────────────

  bool get _isDirty =>
      _fullNameCtrl.text.isNotEmpty ||
      _shortNameCtrl.text.isNotEmpty ||
      _kafedraId != null;

  List<Map<String, dynamic>> get _filteredTeachers {
    if (_kafedraId == null) return [];
    final list = _teachersByKafedra[_kafedraId] ?? [];
    if (_teacherSearch.isEmpty) return list;
    return list
        .where((t) => t['name']
            .toString()
            .toLowerCase()
            .contains(_teacherSearch.toLowerCase()))
        .toList();
  }

  // ── Закрити з перевіркою ───────────────────────────────────────────────────

  Future<void> _tryClose() async {
    if (!_isDirty) {
      Navigator.pop(context);
      return;
    }
    final confirmed = await _showUnsavedDialog();
    if (confirmed && mounted) Navigator.pop(context);
  }

  Future<bool> _showUnsavedDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('У вас є незбережені зміни.',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            content: const Text(
              'Якщо ви закриєте вікно, усі внесені дані буде втрачено. '
              'Ви впевнені, що хочете вийти без збереження?',
              style: TextStyle(fontSize: 14, color: AppTheme.textMid),
            ),
            actionsPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textDark,
                  side: const BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Продовжити'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Закрити'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Підтвердити додавання ──────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Дисципліну "${_fullNameCtrl.text.trim()}" додано'),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _tryClose();
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──────────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ── Заголовок ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
              child: Row(children: [
                const Expanded(
                  child: Text('Додайте нову дисципліну',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                ),
                IconButton(
                  onPressed: _tryClose,
                  icon: const Icon(Icons.close, color: AppTheme.textMid),
                  splashRadius: 20,
                ),
              ]),
            ),
            const Divider(height: 1),

            // ── Форма ───────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Повна назва
                      _FieldLabel('Повна назва дисципліни', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _fullNameCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: _dec('Введіть повну назву дисципліни'),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Обов\'язкове поле'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Скорочена назва
                      _FieldLabel('Скорочена назва', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _shortNameCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: _dec('Напр. ТСА').copyWith(
                          helperText:
                              'Має бути коротко, не більше 10 символів',
                          helperStyle: TextStyle(
                            color: _shortNameCtrl.text.length > 10
                                ? Colors.red
                                : AppTheme.primary,
                            fontSize: 12,
                          ),
                          counterText:
                              '${_shortNameCtrl.text.length}/10',
                          counterStyle: TextStyle(
                            color: _shortNameCtrl.text.length > 10
                                ? Colors.red
                                : AppTheme.textMid,
                            fontSize: 11,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v?.trim().isEmpty ?? true) {
                            return 'Обов\'язкове поле';
                          }
                          if (v!.trim().length > 10) {
                            return 'Максимум 10 символів';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Кафедра
                      _FieldLabel('Кафедра', required: true),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: _kafedraId,
                        decoration: _dec('Оберіть кафедру'),
                        isExpanded: true,
                        items: _kafedrasMock
                            .map((k) => DropdownMenuItem<int>(
                                  value: k['id'] as int,
                                  child: Text(
                                    '${k['name']} — ${k['desc']}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _kafedraId = v;
                          _teacherId = null;
                          _teacherSearch = '';
                        }),
                        validator: (v) =>
                            v == null ? 'Оберіть кафедру' : null,
                      ),
                      const SizedBox(height: 16),

                      // Викладачі (показуємо тільки після вибору кафедри)
                      if (_kafedraId != null) ...[
                        _FieldLabel('Викладач'),
                        const SizedBox(height: 6),
                        TextField(
                          onChanged: (v) =>
                              setState(() => _teacherSearch = v),
                          decoration: _dec('Пошук викладача...').copyWith(
                            prefixIcon: const Icon(Icons.search,
                                size: 18, color: AppTheme.textMid),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _TeacherList(
                          teachers: _filteredTeachers,
                          selectedId: _teacherId,
                          onSelect: (id) => setState(
                              () => _teacherId = _teacherId == id ? null : id),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // ── Кнопки дій ──────────────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 20),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _tryClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textDark,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Скасувати'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Додати дисципліну',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMid, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppTheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      );
}

// ── Список викладачів ─────────────────────────────────────────────────────────

class _TeacherList extends StatelessWidget {
  final List<Map<String, dynamic>> teachers;
  final int? selectedId;
  final void Function(int id) onSelect;

  const _TeacherList({
    required this.teachers,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (teachers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text('Викладачів не знайдено',
              style: TextStyle(color: AppTheme.textMid, fontSize: 13)),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: teachers.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 16),
          itemBuilder: (context, i) {
            final t = teachers[i];
            final id = t['id'] as int;
            final isSelected = selectedId == id;
            return InkWell(
              onTap: () => onSelect(id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                child: Row(children: [
                  Expanded(
                    child: Text(t['name'] as String,
                        style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textDark,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle,
                        color: AppTheme.primary, size: 20)
                  else
                    const Icon(Icons.radio_button_unchecked,
                        color: AppTheme.border, size: 20),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Лейбл поля ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(text,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark)),
      if (required)
        const Text(' *',
            style: TextStyle(color: Colors.red, fontSize: 14)),
    ]);
  }
}
