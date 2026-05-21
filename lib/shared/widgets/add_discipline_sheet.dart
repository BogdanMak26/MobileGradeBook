// lib/shared/widgets/add_discipline_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/repositories.dart';
import '../../features/disciplines/data/repositories/disciplines_repository.dart';
import '../theme/app_theme.dart';

// ── Публічна функція для показу ───────────────────────────────────────────────

Future<void> showAddDisciplineSheet(
  BuildContext context, {
  int? kafedraId,
  VoidCallback? onCreated,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddDisciplineSheet(
      initialKafedraId: kafedraId,
      onCreated: onCreated,
    ),
  );
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

class AddDisciplineSheet extends ConsumerStatefulWidget {
  final int? initialKafedraId;
  final VoidCallback? onCreated;
  const AddDisciplineSheet({super.key, this.initialKafedraId, this.onCreated});

  @override
  ConsumerState<AddDisciplineSheet> createState() => _AddDisciplineSheetState();
}

class _AddDisciplineSheetState extends ConsumerState<AddDisciplineSheet> {
  final _formKey       = GlobalKey<FormState>();
  final _fullNameCtrl  = TextEditingController();
  final _shortNameCtrl = TextEditingController();

  int?   _kafedraId;
  int?   _teacherId;
  String _teacherSearch = '';

  List<Map<String, dynamic>> _kafedras         = [];
  List<Map<String, dynamic>> _teachers         = [];
  bool _loadingKafedras  = true;
  bool _loadingTeachers  = false;
  bool _submitting       = false;

  @override
  void initState() {
    super.initState();
    _kafedraId = widget.initialKafedraId;
    _loadKafedras();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _shortNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKafedras() async {
    try {
      final raw = await ref.read(kafedrasRepositoryProvider).getKafedras();
      if (!mounted) return;
      setState(() {
        _kafedras = raw.cast<Map<String, dynamic>>();
        _loadingKafedras = false;
      });
      if (_kafedraId != null) _loadTeachers();
    } catch (_) {
      if (mounted) setState(() => _loadingKafedras = false);
    }
  }

  Future<void> _loadTeachers() async {
    if (_kafedraId == null) {
      setState(() => _teachers = []);
      return;
    }
    setState(() { _loadingTeachers = true; _teachers = []; _teacherId = null; });
    try {
      final result = await ref.read(userRepositoryProvider)
          .getUsers(role: 'TEACHER', size: 300);
      final content = (result['content'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final filtered = content
          .where((u) => u['kafedraId'] == _kafedraId)
          .map((u) => {
                'id':   u['id'] as int,
                'name': '${u['surname'] ?? ''} ${u['name'] ?? ''}'.trim(),
              })
          .toList();
      if (mounted) setState(() { _teachers = filtered; _loadingTeachers = false; });
    } catch (_) {
      if (mounted) setState(() { _teachers = []; _loadingTeachers = false; });
    }
  }

  bool get _isDirty =>
      _fullNameCtrl.text.isNotEmpty ||
      _shortNameCtrl.text.isNotEmpty ||
      (_kafedraId != null && _kafedraId != widget.initialKafedraId);

  List<Map<String, dynamic>> get _filteredTeachers {
    if (_teacherSearch.isEmpty) return _teachers;
    return _teachers
        .where((t) => t['name']
            .toString()
            .toLowerCase()
            .contains(_teacherSearch.toLowerCase()))
        .toList();
  }

  Future<void> _tryClose() async {
    if (!_isDirty) { Navigator.pop(context); return; }
    final confirmed = await _showUnsavedDialog();
    if (confirmed && mounted) Navigator.pop(context);
  }

  Future<bool> _showUnsavedDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('У вас є незбережені зміни.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            content: const Text(
              'Якщо ви закриєте вікно, усі внесені дані буде втрачено. '
              'Ви впевнені, що хочете вийти без збереження?',
              style: TextStyle(fontSize: 14, color: AppTheme.textMid),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textDark,
                  side: const BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Продовжити'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Закрити'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(disciplinesRepositoryProvider).createDiscipline({
        'fullName':  _fullNameCtrl.text.trim(),
        'shortName': _shortNameCtrl.text.trim(),
        'kafedraId': _kafedraId,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Дисципліну "${_fullNameCtrl.text.trim()}" додано'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Помилка: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

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
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
              child: Row(children: [
                const Expanded(
                  child: Text('Додайте нову дисципліну',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                ),
                IconButton(
                  onPressed: _tryClose,
                  icon: const Icon(Icons.close, color: AppTheme.textMid),
                ),
              ]),
            ),
            const Divider(height: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _FieldLabel('Повна назва дисципліни', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _fullNameCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: _dec('Введіть повну назву дисципліни'),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Обов\'язкове поле' : null,
                      ),
                      const SizedBox(height: 16),

                      _FieldLabel('Скорочена назва', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _shortNameCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: _dec('Напр. ТСА').copyWith(
                          helperText: 'Має бути коротко, не більше 10 символів',
                          helperStyle: TextStyle(
                            color: _shortNameCtrl.text.length > 10 ? Colors.red : AppTheme.primary,
                            fontSize: 12,
                          ),
                          counterText: '${_shortNameCtrl.text.length}/10',
                          counterStyle: TextStyle(
                            color: _shortNameCtrl.text.length > 10 ? Colors.red : AppTheme.textMid,
                            fontSize: 11,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v?.trim().isEmpty ?? true) return 'Обов\'язкове поле';
                          if (v!.trim().length > 10) return 'Максимум 10 символів';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _FieldLabel('Кафедра', required: true),
                      const SizedBox(height: 6),
                      if (_loadingKafedras)
                        const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        DropdownButtonFormField<int>(
                          value: _kafedraId,
                          decoration: _dec('Оберіть кафедру'),
                          isExpanded: true,
                          items: _kafedras.map((k) => DropdownMenuItem<int>(
                            value: k['id'] as int?,
                            child: Text(
                              'Кафедра №${k['number'] ?? k['kafedraNumber'] ?? '?'} — ${k['name'] ?? ''}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          )).toList(),
                          onChanged: widget.initialKafedraId != null
                              ? null
                              : (v) {
                                  setState(() { _kafedraId = v; _teacherSearch = ''; });
                                  _loadTeachers();
                                },
                          validator: (v) => v == null ? 'Оберіть кафедру' : null,
                        ),
                      const SizedBox(height: 16),

                      if (_kafedraId != null) ...[
                        _FieldLabel('Викладач (необов\'язково)'),
                        const SizedBox(height: 6),
                        TextField(
                          onChanged: (v) => setState(() => _teacherSearch = v),
                          decoration: _dec('Пошук викладача...').copyWith(
                            prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMid),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_loadingTeachers)
                          const Center(child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          _TeacherList(
                            teachers: _filteredTeachers,
                            selectedId: _teacherId,
                            onSelect: (id) => setState(() => _teacherId = _teacherId == id ? null : id),
                          ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 20),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : _tryClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textDark,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Скасувати'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Додати дисципліну',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      );
}

// ── Список викладачів ─────────────────────────────────────────────────────────

class _TeacherList extends StatelessWidget {
  final List<Map<String, dynamic>> teachers;
  final int? selectedId;
  final void Function(int id) onSelect;
  const _TeacherList({required this.teachers, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (teachers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(10)),
        child: const Center(
          child: Text('Викладачів не знайдено',
              style: TextStyle(color: AppTheme.textMid, fontSize: 13)),
        ),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: teachers.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
          itemBuilder: (context, i) {
            final t = teachers[i];
            final id = t['id'] as int;
            final isSelected = selectedId == id;
            return InkWell(
              onTap: () => onSelect(id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  Expanded(
                    child: Text(t['name'] as String,
                        style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? AppTheme.primary : AppTheme.textDark,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
                  else
                    const Icon(Icons.radio_button_unchecked, color: AppTheme.border, size: 20),
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
      Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
      if (required) const Text(' *', style: TextStyle(color: Colors.red, fontSize: 14)),
    ]);
  }
}
