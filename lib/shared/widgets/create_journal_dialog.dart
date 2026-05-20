// lib/shared/widgets/create_journal_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/repositories.dart';
import '../theme/app_theme.dart';

class CreateJournalDialog extends ConsumerStatefulWidget {
  final int disciplineId;
  final String disciplineName;
  final VoidCallback? onCreated;
  const CreateJournalDialog({
    super.key,
    required this.disciplineId,
    required this.disciplineName,
    this.onCreated,
  });

  @override
  ConsumerState<CreateJournalDialog> createState() => _CreateJournalDialogState();
}

class _CreateJournalDialogState extends ConsumerState<CreateJournalDialog> {
  List<Map<String, dynamic>> _groups    = [];
  List<Map<String, dynamic>> _semesters = [];
  Map<String, dynamic>?      _selectedGroup;
  final Set<int>             _selectedSemesterIds = {};
  bool _loadingGroups    = true;
  bool _loadingSemesters = false;
  bool _submitting       = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final raw = await ref.read(groupsRepositoryProvider).getGroups();
      if (mounted) setState(() { _groups = raw.cast<Map<String, dynamic>>(); _loadingGroups = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingGroups = false);
    }
  }

  Future<void> _onGroupSelected(Map<String, dynamic>? g) async {
    setState(() {
      _selectedGroup = g;
      _semesters = [];
      _selectedSemesterIds.clear();
    });
    if (g == null) return;
    final groupId = g['id'] as int?;
    if (groupId == null) return;
    setState(() => _loadingSemesters = true);
    try {
      final raw = await ref.read(semestersRepositoryProvider).getSemestersByGroup(groupId);
      if (mounted) setState(() { _semesters = raw.cast<Map<String, dynamic>>(); _loadingSemesters = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSemesters = false);
    }
  }

  Future<void> _submit() async {
    final groupId = _selectedGroup?['id'] as int?;
    if (groupId == null || _selectedSemesterIds.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(journalsRepositoryProvider).createJournal({
        'disciplineId': widget.disciplineId,
        'groupId':      groupId,
        'semesterIds':  _selectedSemesterIds.toList(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Журнал створено'),
          backgroundColor: Color(0xFF16A34A),
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
    final canSubmit = _selectedGroup != null && _selectedSemesterIds.isNotEmpty && !_submitting;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Expanded(
                child: Text('Створити журнал',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDark)),
              ),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ]),
            const Divider(height: 20),

            const Text('Дисципліна', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textMid)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.surface,
              ),
              child: Row(children: [
                Expanded(child: Text(widget.disciplineName,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                    overflow: TextOverflow.ellipsis)),
                const Icon(Icons.lock_outline, color: AppTheme.textLight, size: 16),
              ]),
            ),
            const SizedBox(height: 14),

            const Text('Група *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textMid)),
            const SizedBox(height: 6),
            if (_loadingGroups)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedGroup,
                hint: const Text('Оберіть групу', style: TextStyle(fontSize: 13)),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                isExpanded: true,
                items: _groups.map((g) => DropdownMenuItem(
                  value: g,
                  child: Text(
                    '${g['name']} (${g['yearStart'] ?? g['year'] ?? ''})',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: _onGroupSelected,
              ),
            const SizedBox(height: 14),

            const Text('Семестри *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textMid)),
            const SizedBox(height: 8),
            if (_selectedGroup == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Спочатку оберіть групу',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMid, fontStyle: FontStyle.italic)),
              )
            else if (_loadingSemesters)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (_semesters.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Семестрів не знайдено',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _semesters.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final s = _semesters[i];
                      final id = s['id'] as int? ?? 0;
                      final num = s['number'] as int? ?? s['semesterNumber'] as int? ?? (i + 1);
                      final y1 = s['yearStart'] as int?;
                      final y2 = s['yearEnd'] as int?;
                      final label = y1 != null ? 'Семестр $num ($y1–$y2)' : 'Семестр $num';
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        title: Text(label, style: const TextStyle(fontSize: 13)),
                        value: _selectedSemesterIds.contains(id),
                        onChanged: (v) => setState(() {
                          if (v == true) _selectedSemesterIds.add(id);
                          else _selectedSemesterIds.remove(id);
                        }),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppTheme.primary,
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF374151),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Скасувати'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.border,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Створити журнал'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
