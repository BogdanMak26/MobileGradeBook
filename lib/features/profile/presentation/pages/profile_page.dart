// lib/features/profile/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/auth/biometric_preferences.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _bodyFade;

  late String _firstName;
  late String _lastName;
  late String? _rank;
  late String? _position;
  String _phone = '';
  String? _birthDate;
  String _gender = 'Чоловік';

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authViewModelProvider);
    final user = auth.role == 'CADET'
        ? MockDataProvider.cadetUser
        : MockDataProvider.currentUser;
    _firstName = user.name;
    _lastName = user.surname;
    _rank = user.rank;
    _position = user.position;

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _bodyFade = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final user = auth.role == 'CADET'
        ? MockDataProvider.cadetUser
        : MockDataProvider.currentUser;

    final displayName = '$_lastName $_firstName'.trim();
    final initials = displayName.split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero Header ──────────────────────────────────────────────
            SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerFade,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1E1B4B),
                        Color(0xFF433F31),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        children: [
                          // Назад
                          Row(children: [
                            GestureDetector(
                              onTap: () => Navigator.maybePop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.arrow_back,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                            const Spacer(),
                            const Text('Профіль',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showEditDialog(context, user),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.edit_outlined,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 24),

                          // Аватар
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(initials,
                                  style: const TextStyle(
                                      fontSize: 30,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Ім'я
                          Text(displayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 6),
                          Text(user.email,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 13)),
                          const SizedBox(height: 12),

                          // Роль badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppTheme.primary.withOpacity(0.5)),
                            ),
                            child: Text(
                              UserRole.displayName(auth.role ?? ''),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Картки інформації ────────────────────────────────────────
            FadeTransition(
              opacity: _bodyFade,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Посада / звання
                    if (_rank != null || _position != null) ...[
                      _SectionHeader(
                          icon: Icons.military_tech_rounded,
                          title: 'Посада'),
                      _InfoCard(items: [
                        if (_rank != null)
                          _InfoRow(
                              icon: Icons.star_outline,
                              label: 'Звання',
                              value: _rank!),
                        if (_position != null)
                          _InfoRow(
                              icon: Icons.badge_outlined,
                              label: 'Посада',
                              value: _position!),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    // Підрозділ
                    if (user.kafedraName != null) ...[
                      _SectionHeader(
                          icon: Icons.school_rounded,
                          title: 'Підрозділ'),
                      _InfoCard(items: [
                        _InfoRow(
                            icon: Icons.business_outlined,
                            label: 'Кафедра',
                            value: user.kafedraName!),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    // Навчання
                    if (user.groupName != null) ...[
                      _SectionHeader(
                          icon: Icons.groups_rounded,
                          title: 'Навчання'),
                      _InfoCard(items: [
                        _InfoRow(
                            icon: Icons.group_outlined,
                            label: 'Група',
                            value: user.groupName!),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    // Контакти
                    _SectionHeader(
                        icon: Icons.contact_mail_rounded,
                        title: 'Контакти'),
                    _InfoCard(items: [
                      _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user.email),
                    ]),
                    const SizedBox(height: 16),

                    // Налаштування
                    _SectionHeader(
                        icon: Icons.settings_rounded,
                        title: 'Налаштування'),
                    _SettingsCard(items: [
                      _SettingsItemData(
                          icon: Icons.notifications_outlined,
                          label: 'Сповіщення',
                          iconColor: const Color(0xFF0284C7),
                          onTap: () => context.push('/notifications')),
                    ]),
                    const SizedBox(height: 8),
                    _BiometricSettingsTile(role: auth.role ?? ''),
                    const SizedBox(height: 8),
                    _SettingsCard(items: [
                      _SettingsItemData(
                          icon: Icons.language_rounded,
                          label: 'Мова',
                          trailing: 'Українська',
                          iconColor: const Color(0xFF059669),
                          onTap: () {}),
                      _SettingsItemData(
                          icon: Icons.info_outline_rounded,
                          label: 'Про застосунок',
                          trailing: 'v1.0.0',
                          iconColor: AppTheme.secondary,
                          onTap: () {}),
                    ]),
                    const SizedBox(height: 12),

                    // Вийти
                    _SettingsCard(items: [
                      _SettingsItemData(
                          icon: Icons.logout_rounded,
                          label: 'Вийти з системи',
                          labelColor: const Color(0xFFDC2626),
                          iconColor: const Color(0xFFDC2626),
                          onTap: () => _confirmLogout(context, ref)),
                    ]),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _allRanks = [
    'Працівник ЗСУ',
    'Солдат',
    'Старший солдат',
    'Молодший сержант',
    'Сержант',
    'Старший сержант',
    'Головний сержант',
    'Штаб-сержант',
    'Майстер-сержант',
    'Старший майстер-сержант',
    'Головний майстер-сержант',
    'Молодший лейтенант',
    'Лейтенант',
    'Старший лейтенант',
    'Капітан',
    'Майор',
    'Підполковник',
    'Полковник',
    'Бригадний генерал',
    'Генерал-майор',
  ];

  static const _positionGroups = <(String, List<String>)>[
    ('Курсанти та слухачі', [
      'Курсант', 'Слухач', 'Журналіст',
      'Командир відділення', 'Командир групи',
    ]),
    ('Командний склад курсу', [
      'Головний сержант курсу', 'Начальник навчального курсу',
      'Курсовий офіцер', 'Старший помічник',
    ]),
    ('Науково-педагогічний склад', [
      'Викладач', 'Старший викладач', 'Доцент', 'Професор',
      'Заступник начальника кафедри', 'Начальник кафедри',
    ]),
    ('Наукові співробітники', [
      'Провідний науковий співробітник',
      'Старший науковий співробітник',
    ]),
    ('Факультет', [
      'Заступник начальника факультету з навчальної роботи',
      'Начальник факультету',
    ]),
    ('Навчальний відділ', [
      'Заступник начальника НВ', 'Ст. помічник начальника НВ',
      'Помічник начальника НВ',
      'Заступник начальника навчального відділу',
      'Начальник навчального відділу',
    ]),
    ('ГОСДН', ['Начальник ГОСДН', 'Ст.офіцер ГОСДН']),
    ('НМК', ['Завідувач НМ кабінетом', 'Методист НМК']),
    ('Керівництво інституту', [
      'Начальник інституту',
      'Заступник начальника інституту з навчальної роботи',
      'ЗНІ з логістики',
      'Начальник відділу контролю якості освіти',
      'Начальник відділу ЗЯОДВО',
    ]),
  ];

  static const _genders = ['Чоловік', 'Жінка'];

  void _showEditDialog(BuildContext context, MockUser user) {
    final isCadet = user.role == 'CADET';
    final lastNameCtrl  = TextEditingController(text: _lastName);
    final firstNameCtrl = TextEditingController(text: _firstName);
    final phoneCtrl     = TextEditingController(text: _phone);

    final allPositions = _positionGroups
        .expand((g) => g.$2)
        .toList();

    String selectedGender = _gender;
    String? selectedRank  = (_rank != null && _allRanks.contains(_rank))
        ? _rank : _allRanks.first;
    String? selectedPos   = (_position != null && allPositions.contains(_position))
        ? _position : allPositions.first;
    String? selectedBirth = _birthDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Редагування профілю',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),

                  // ── Основна інформація ──────────────────────────────
                  const SizedBox(height: 20),
                  _SheetSection(title: 'Основна інформація'),
                  const SizedBox(height: 12),

                  Row(children: [
                    Expanded(child: _EditField(
                        controller: firstNameCtrl, label: "ІМ'Я")),
                    const SizedBox(width: 12),
                    Expanded(child: _EditField(
                        controller: lastNameCtrl, label: 'ПРІЗВИЩЕ')),
                  ]),
                  const SizedBox(height: 12),

                  // Email — НЕ редагується
                  _NonEditableField(label: 'EMAIL', value: user.email),
                  const SizedBox(height: 12),

                  Row(children: [
                    Expanded(child: _EditField(
                        controller: phoneCtrl,
                        label: 'ТЕЛЕФОН',
                        keyboard: TextInputType.phone)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DropdownField<String>(
                        label: 'СТАТЬ',
                        value: selectedGender,
                        items: _genders,
                        onChanged: (v) =>
                            setSheet(() => selectedGender = v!),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Дата народження
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                        locale: const Locale('uk'),
                      );
                      if (picked != null) {
                        setSheet(() => selectedBirth =
                            '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}');
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'ДАТА НАРОДЖЕННЯ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10))),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        suffixIcon: Icon(Icons.calendar_today_outlined,
                            size: 18),
                      ),
                      child: Text(
                        selectedBirth ?? 'дд.мм.рррр',
                        style: TextStyle(
                          fontSize: 14,
                          color: selectedBirth != null
                              ? AppTheme.textDark
                              : AppTheme.textLight,
                        ),
                      ),
                    ),
                  ),

                  // ── Навчальна / Службова інформація ────────────────
                  const SizedBox(height: 20),
                  _SheetSection(
                      title: isCadet
                          ? 'Навчальна інформація'
                          : 'Службова інформація'),
                  const SizedBox(height: 12),

                  if (isCadet) ...[
                    Row(children: [
                      Expanded(child: _NonEditableField(
                          label: 'НАВЧАЛЬНА ГРУПА',
                          value: user.groupName ?? '—')),
                      const SizedBox(width: 12),
                      Expanded(child: _NonEditableField(
                          label: 'ФАКУЛЬТЕТ',
                          value: 'Факультет ІТ')),
                    ]),
                    const SizedBox(height: 12),
                  ] else ...[
                    _NonEditableField(
                        label: 'КАФЕДРА',
                        value: user.kafedraName ?? '—'),
                    const SizedBox(height: 12),
                  ],

                  _DropdownField<String>(
                    label: 'ЗВАННЯ',
                    value: selectedRank,
                    items: _allRanks,
                    onChanged: (v) => setSheet(() => selectedRank = v),
                  ),
                  const SizedBox(height: 12),
                  _GroupedPositionDropdown(
                    label: 'ПОСАДА',
                    value: selectedPos,
                    groups: _positionGroups,
                    onChanged: (v) => setSheet(() => selectedPos = v),
                  ),

                  // ── Кнопки ─────────────────────────────────────────
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Скасувати'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final newLast  = lastNameCtrl.text.trim();
                          final newFirst = firstNameCtrl.text.trim();
                          if (newLast.isEmpty || newFirst.isEmpty) return;

                          Navigator.pop(ctx);
                          setState(() {
                            _lastName  = newLast;
                            _firstName = newFirst;
                            _phone     = phoneCtrl.text.trim();
                            _gender    = selectedGender;
                            _birthDate = selectedBirth;
                            _rank      = selectedRank;
                            _position  = selectedPos;
                          });
                          ref
                              .read(authViewModelProvider.notifier)
                              .updateProfile(
                                  fullName: '$newLast $newFirst');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Зберегти',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Вийти?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text('Ви впевнені, що хочете вийти з системи?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Вийти'),
          ),
        ],
      ),
    );
    // logout викликається тільки після повного закриття діалогу
    if (confirmed == true && context.mounted) {
      ref.read(authViewModelProvider.notifier).logout();
    }
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                letterSpacing: 0.3)),
      ]),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon,
                      color: AppTheme.textMid, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label,
                          style: const TextStyle(
                              color: AppTheme.textMid,
                              fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(item.value,
                          style: const TextStyle(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ]),
            ),
            if (!isLast)
              const Divider(height: 1, indent: 62),
          ]);
        }).toList(),
      ),
    );
  }
}

// ── Biometric Settings Tile ───────────────────────────────────────────────────

class _BiometricSettingsTile extends ConsumerWidget {
  final String role;
  const _BiometricSettingsTile({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bio = ref.watch(biometricProvider);

    if (!bio.isInitialized || !bio.canUse) return const SizedBox.shrink();

    final color = const Color(0xFF7C3AED);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              bio.primaryType == BiometricType.face
                  ? Icons.face_outlined
                  : Icons.fingerprint,
              color: color,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Біометричний вхід',
                    style: TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w500,
                        fontSize: 14)),
                Text(bio.typeLabel,
                    style: const TextStyle(
                        color: AppTheme.textMid, fontSize: 11)),
              ],
            ),
          ),
          Switch.adaptive(
            value: bio.isEnabled,
            activeColor: color,
            onChanged: (v) async {
              HapticFeedback.selectionClick();
              final notifier = ref.read(biometricProvider.notifier);
              if (v) {
                final ok = await notifier.enable(role: role);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Не вдалося увімкнути біометрію'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                await notifier.disable();
              }
            },
          ),
        ]),
      ),
    );
  }
}

// ── Settings Card ─────────────────────────────────────────────────────────────

class _SettingsItemData {
  final IconData icon;
  final String label;
  final String? trailing;
  final Color? labelColor;
  final Color iconColor;
  final VoidCallback onTap;
  const _SettingsItemData({
    required this.icon,
    required this.label,
    this.trailing,
    this.labelColor,
    required this.iconColor,
    required this.onTap,
  });
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsItemData> items;
  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: e.key == 0
                      ? const Radius.circular(14)
                      : Radius.zero,
                  bottom: isLast
                      ? const Radius.circular(14)
                      : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: item.iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(item.icon, color: item.iconColor, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item.label,
                          style: TextStyle(
                              color: item.labelColor ?? AppTheme.textDark,
                              fontWeight: FontWeight.w500,
                              fontSize: 14)),
                    ),
                    if (item.trailing != null)
                      Text(item.trailing!,
                          style: const TextStyle(
                              color: AppTheme.textMid, fontSize: 13)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        color: item.labelColor?.withOpacity(0.5) ??
                            AppTheme.textLight,
                        size: 18),
                  ]),
                ),
              ),
            ),
            if (!isLast) const Divider(height: 1, indent: 62),
          ]);
        }).toList(),
      ),
    );
  }
}

// ── Edit helpers ──────────────────────────────────────────────────────────────

class _SheetSection extends StatelessWidget {
  final String title;
  const _SheetSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark)),
      const SizedBox(height: 6),
      Container(height: 2, width: 32, color: AppTheme.primary),
    ]);
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboard;
  const _EditField({
    required this.controller,
    required this.label,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMid),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _NonEditableField extends StatelessWidget {
  final String label;
  final String value;
  const _NonEditableField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMid)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textMid,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 2),
        const Text('(недоступно для редагування)',
            style: TextStyle(
                fontSize: 10,
                color: AppTheme.textLight,
                fontStyle: FontStyle.italic)),
      ]),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMid),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(e.toString()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Grouped position dropdown ─────────────────────────────────────────────────

class _GroupedPositionDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<(String, List<String>)> groups;
  final ValueChanged<String?> onChanged;

  const _GroupedPositionDropdown({
    required this.label,
    required this.value,
    required this.groups,
    required this.onChanged,
  });

  List<DropdownMenuItem<String>> _buildItems() {
    final items = <DropdownMenuItem<String>>[];
    for (final (groupName, positions) in groups) {
      // Group header — not selectable
      items.add(DropdownMenuItem<String>(
        value: '__group__$groupName',
        enabled: false,
        child: Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            groupName,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMid),
          ),
        ),
      ));
      for (final pos in positions) {
        items.add(DropdownMenuItem<String>(
          value: pos,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(pos,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textDark)),
          ),
        ));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMid),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
          items: _buildItems(),
          onChanged: (v) {
            if (v != null && !v.startsWith('__group__')) {
              onChanged(v);
            }
          },
        ),
      ),
    );
  }
}
