// lib/features/notifications/presentation/pages/notifications_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/notification_preferences.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../shared/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class _TimingOption {
  final String value;
  final String label;
  const _TimingOption(this.value, this.label);
}

class _NotifItemData {
  final IconData icon;
  final String key;
  final String title;
  final String subtitle;
  final String? timingKey;
  final String? timingLabel;
  final List<_TimingOption>? timingOptions;

  const _NotifItemData({
    required this.icon,
    required this.key,
    required this.title,
    required this.subtitle,
    this.timingKey,
    this.timingLabel,
    this.timingOptions,
  });
}

class _NotifCategory {
  final IconData icon;
  final String title;
  final Color color;
  final List<_NotifItemData> items;

  const _NotifCategory({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Role-specific category definitions
// ─────────────────────────────────────────────────────────────────────────────

List<_NotifCategory> _categoriesForRole(String role) {
  switch (role) {
    case UserRole.cadet:
      return [
        _NotifCategory(
          icon: Icons.school_rounded,
          title: 'Навчальний процес',
          color: const Color(0xFF0284C7),
          items: [
            _NotifItemData(
              icon: Icons.assignment_turned_in_rounded,
              key: NotifKey.importantClasses,
              title: 'Важливі заняття',
              subtitle: 'Заліки, іспити, модульні КР, практичні роботи',
              timingKey: NotifKey.importantClassesTime,
              timingLabel: 'Нагадати за:',
              timingOptions: const [
                _TimingOption('1h',  '1 годину'),
                _TimingOption('24h', '24 години'),
                _TimingOption('48h', '48 годин'),
              ],
            ),
            _NotifItemData(
              icon: Icons.grade_rounded,
              key: NotifKey.newGrades,
              title: 'Нові оцінки',
              subtitle: 'Коли викладач виставляє нову оцінку',
            ),
            _NotifItemData(
              icon: Icons.warning_amber_rounded,
              key: NotifKey.lowGrades,
              title: 'Низькі оцінки',
              subtitle: 'Якщо виставлена оцінка нижче 60 балів',
            ),
          ],
        ),
        _NotifCategory(
          icon: Icons.calendar_month_rounded,
          title: 'Розклад занять',
          color: const Color(0xFF059669),
          items: [
            _NotifItemData(
              icon: Icons.update_rounded,
              key: NotifKey.scheduleChanges,
              title: 'Зміни в розкладі',
              subtitle: 'Переноси, нові заняття або зміни аудиторій',
            ),
            _NotifItemData(
              icon: Icons.event_busy_rounded,
              key: NotifKey.classCancellation,
              title: 'Скасування занять',
              subtitle: 'Коли одне з ваших занять скасовано',
            ),
          ],
        ),
        _NotifCategory(
          icon: Icons.campaign_rounded,
          title: 'Оголошення',
          color: const Color(0xFF7C3AED),
          items: [
            _NotifItemData(
              icon: Icons.announcement_rounded,
              key: NotifKey.deptAnnouncements,
              title: 'Повідомлення від кафедри',
              subtitle: 'Важливі оголошення, накази та розпорядження',
            ),
          ],
        ),
      ];

    case UserRole.instructor:
      return [
        _NotifCategory(
          icon: Icons.book_rounded,
          title: 'Журнали та оцінювання',
          color: AppTheme.primary,
          items: [
            _NotifItemData(
              icon: Icons.edit_note_rounded,
              key: NotifKey.unfilledJournals,
              title: 'Незаповнені журнали',
              subtitle: 'Нагадування про журнали, що потребують заповнення',
            ),
            _NotifItemData(
              icon: Icons.alarm_rounded,
              key: NotifKey.beforeClassReminder,
              title: 'Нагадування перед заняттям',
              subtitle: 'Завчасне повідомлення про початок заняття',
              timingKey: NotifKey.beforeClassTime,
              timingLabel: 'Нагадати за:',
              timingOptions: const [
                _TimingOption('15m', '15 хвилин'),
                _TimingOption('30m', '30 хвилин'),
                _TimingOption('1h',  '1 годину'),
              ],
            ),
          ],
        ),
        _NotifCategory(
          icon: Icons.calendar_month_rounded,
          title: 'Розклад',
          color: const Color(0xFF059669),
          items: [
            _NotifItemData(
              icon: Icons.manage_history_rounded,
              key: NotifKey.myScheduleChanges,
              title: 'Зміни у власному розкладі',
              subtitle: 'Зміни саме у вашому персональному розкладі',
            ),
            _NotifItemData(
              icon: Icons.event_busy_rounded,
              key: NotifKey.classCancellation,
              title: 'Скасування занять',
              subtitle: 'Коли одне з ваших занять скасовано',
            ),
          ],
        ),
        _NotifCategory(
          icon: Icons.groups_rounded,
          title: 'Курсанти',
          color: const Color(0xFF4338CA),
          items: [
            _NotifItemData(
              icon: Icons.person_add_rounded,
              key: NotifKey.newCadets,
              title: 'Нові курсанти в групах',
              subtitle: 'Коли до ваших груп зараховують нових курсантів',
            ),
          ],
        ),
      ];

    case UserRole.departmentHead:
      return [
        _NotifCategory(
          icon: Icons.bar_chart_rounded,
          title: 'Успішність кафедри',
          color: const Color(0xFF0891B2),
          items: [
            _NotifItemData(
              icon: Icons.summarize_rounded,
              key: NotifKey.weeklyDigest,
              title: 'Тижневий дайджест',
              subtitle: 'Щотижневий звіт успішності всіх груп кафедри',
            ),
            _NotifItemData(
              icon: Icons.trending_down_rounded,
              key: NotifKey.criticalPerformance,
              title: 'Критична успішність',
              subtitle: 'Якщо середній бал групи падає нижче 60%',
            ),
            _NotifItemData(
              icon: Icons.calendar_view_month_rounded,
              key: NotifKey.monthlyReport,
              title: 'Місячний звіт',
              subtitle: 'Детальний аналітичний звіт у кінці місяця',
            ),
          ],
        ),
        _NotifCategory(
          icon: Icons.book_rounded,
          title: 'Журнали викладачів',
          color: AppTheme.primary,
          items: [
            _NotifItemData(
              icon: Icons.edit_off_rounded,
              key: NotifKey.unfilledInstructorJournals,
              title: 'Незаповнені журнали',
              subtitle: 'Журнали, які викладачі ще не заповнили',
            ),
            _NotifItemData(
              icon: Icons.timer_off_rounded,
              key: NotifKey.overdueJournals,
              title: 'Прострочені журнали',
              subtitle: 'Журнали, термін подачі яких вже минув',
            ),
          ],
        ),
        _NotifCategory(
          icon: Icons.calendar_month_rounded,
          title: 'Розклад кафедри',
          color: const Color(0xFF059669),
          items: [
            _NotifItemData(
              icon: Icons.schedule_rounded,
              key: NotifKey.deptSchedule,
              title: 'Зміни в розкладі',
              subtitle: 'Будь-які зміни в розкладі всієї кафедри',
            ),
          ],
        ),
      ];

    default: // SUPER_ADMIN, FACULTY_EDUCATION_OFFICE, INSTITUTE_EDUCATION_OFFICE
      return [
        _NotifCategory(
          icon: Icons.settings_suggest_rounded,
          title: 'Система',
          color: const Color(0xFF475569),
          items: [
            _NotifItemData(
              icon: Icons.person_add_alt_1_rounded,
              key: NotifKey.newUsers,
              title: 'Нові реєстрації',
              subtitle: 'Нові користувачі, що очікують підтвердження',
            ),
            _NotifItemData(
              icon: Icons.sync_problem_rounded,
              key: NotifKey.syncErrors,
              title: 'Помилки синхронізації',
              subtitle: 'Критичні збої при синхронізації даних',
            ),
          ],
        ),
        _NotifCategory(
          icon: Icons.bar_chart_rounded,
          title: 'Аналітика та звіти',
          color: const Color(0xFF0891B2),
          items: [
            _NotifItemData(
              icon: Icons.assessment_rounded,
              key: NotifKey.weeklyReports,
              title: 'Тижневі звіти',
              subtitle: 'Щотижневий зріз успішності по факультету/інституту',
            ),
            _NotifItemData(
              icon: Icons.notifications_active_rounded,
              key: NotifKey.criticalIndicators,
              title: 'Критичні показники',
              subtitle: 'Різке падіння успішності або відвідуваності',
            ),
          ],
        ),
        _NotifCategory(
          icon: Icons.account_tree_rounded,
          title: 'Структура',
          color: const Color(0xFFD97706),
          items: [
            _NotifItemData(
              icon: Icons.group_add_rounded,
              key: NotifKey.groupChanges,
              title: 'Зміни в групах',
              subtitle: 'Додавання, видалення або перейменування груп',
            ),
            _NotifItemData(
              icon: Icons.library_add_rounded,
              key: NotifKey.disciplineChanges,
              title: 'Зміни в дисциплінах',
              subtitle: 'Нові або змінені навчальні дисципліни',
            ),
          ],
        ),
      ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Test notification content per role
// ─────────────────────────────────────────────────────────────────────────────

({String title, String body}) _testNotifFor(String role) {
  switch (role) {
    case UserRole.cadet:
      return (
        title: 'Важливе заняття завтра',
        body: 'Завтра о 09:00 — Залік з вищої математики (ауд. 307). Підготуйтесь заздалегідь!',
      );
    case UserRole.instructor:
      return (
        title: 'Нагадування про журнал',
        body: 'Журнал з дисципліни "Програмування" за 07.05.2026 ще не заповнений.',
      );
    case UserRole.departmentHead:
      return (
        title: 'Тижневий дайджест кафедри',
        body: 'Середня успішність: 72.4%. Група ВС-231 має критичний показник — 54.1%.',
      );
    default:
      return (
        title: 'Системне сповіщення',
        body: '3 нові реєстрації очікують підтвердження. Синхронізація завершена успішно.',
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsSettingsPage extends ConsumerStatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  ConsumerState<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState
    extends ConsumerState<NotificationsSettingsPage>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _headerFade;
  late final Animation<double> _bodyFade;
  late final Animation<Offset> _bodySlide;

  bool _hasPermission = true;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _bodyFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _bodySlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    ));
    _entranceCtrl.forward();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final svc = ref.read(notificationServiceProvider);
    await svc.initialize();
    final has = await svc.hasPermission();
    if (mounted) setState(() { _hasPermission = has; _checkingPermission = false; });
  }

  Future<void> _requestPermission() async {
    final svc = ref.read(notificationServiceProvider);
    final granted = await svc.requestPermission();
    if (mounted) setState(() => _hasPermission = granted);
    if (granted) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Сповіщення дозволено'),
          backgroundColor: Color(0xFF059669),
        ));
      }
    }
  }

  Future<void> _sendTestNotification() async {
    HapticFeedback.mediumImpact();
    final svc  = ref.read(notificationServiceProvider);
    final role = ref.read(authViewModelProvider).role ?? UserRole.cadet;
    final info = _testNotifFor(role);
    if (!_hasPermission) {
      await _requestPermission();
      if (!_hasPermission) return;
    }
    await svc.show(title: info.title, body: info.body);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role       = ref.watch(authViewModelProvider.select((s) => s.role ?? UserRole.cadet));
    final settings   = ref.watch(notificationSettingsProvider);
    final categories = _categoriesForRole(role);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _headerFade,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.notifications_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Сповіщення',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Налаштуйте, які сповіщення ви хочете отримувати',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _bodyFade,
                  child: SlideTransition(
                    position: _bodySlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Master toggle
                        _MasterToggleCard(settings: settings),
                        const SizedBox(height: 12),

                        // Permission banner
                        if (!_checkingPermission && !_hasPermission) ...[
                          _PermissionBanner(onGrant: _requestPermission),
                          const SizedBox(height: 12),
                        ],

                        // Categories
                        ...categories.asMap().entries.map((e) {
                          return _AnimatedEntry(
                            index: e.key,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _CategorySection(
                                category: e.value,
                                settings: settings,
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 8),

                        // Test notification button
                        _AnimatedEntry(
                          index: categories.length + 1,
                          child: _TestNotificationButton(
                            onTap: _sendTestNotification,
                            enabled: settings.masterEnabled,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Master toggle card
// ─────────────────────────────────────────────────────────────────────────────

class _MasterToggleCard extends ConsumerWidget {
  final NotificationSettings settings;
  const _MasterToggleCard({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = settings.masterEnabled;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFFF3E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enabled ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? AppTheme.primary.withOpacity(0.35)
              : AppTheme.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: enabled
                ? AppTheme.primary.withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: enabled
                    ? AppTheme.primary.withOpacity(0.15)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                enabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_outlined,
                color: enabled ? AppTheme.primary : AppTheme.textLight,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Отримувати сповіщення',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: enabled ? AppTheme.textDark : AppTheme.textMid,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      enabled
                          ? 'Увімкнено: ${settings.enabledCount} з ${settings.totalCount}'
                          : 'Всі сповіщення вимкнено',
                      key: ValueKey(enabled),
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled ? AppTheme.primary : AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggle(NotifKey.master, v);
              },
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permission banner
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onGrant;
  const _PermissionBanner({required this.onGrant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Дозвіл на сповіщення',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Дозвольте GradeBook надсилати сповіщення на ваш пристрій',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onGrant,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Дозволити',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category section
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final _NotifCategory category;
  final NotificationSettings settings;

  const _CategorySection({
    required this.category,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(category.icon, color: category.color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                category.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: category.color,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        category.color.withOpacity(0.3),
                        category.color.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items card
        Container(
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
            children: category.items.asMap().entries.map((e) {
              final isLast = e.key == category.items.length - 1;
              return Column(
                children: [
                  _NotifItemWidget(
                    item: e.value,
                    categoryColor: category.color,
                    settings: settings,
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, indent: 56, endIndent: 16,
                        color: Color(0xFFF1F5F9)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification item widget
// ─────────────────────────────────────────────────────────────────────────────

class _NotifItemWidget extends ConsumerWidget {
  final _NotifItemData item;
  final Color categoryColor;
  final NotificationSettings settings;

  const _NotifItemWidget({
    required this.item,
    required this.categoryColor,
    required this.settings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled  = settings.isEnabled(item.key);
    final masterOn   = settings.masterEnabled;
    final hasTimings = item.timingOptions != null && item.timingKey != null;

    return Opacity(
      opacity: masterOn ? 1.0 : 0.5,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 1),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? categoryColor.withOpacity(0.12)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    size: 17,
                    color: isEnabled ? categoryColor : AppTheme.textLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isEnabled
                              ? AppTheme.textDark
                              : AppTheme.textMid,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: isEnabled,
                  onChanged: masterOn
                      ? (v) {
                          HapticFeedback.selectionClick();
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .toggle(item.key, v);
                        }
                      : null,
                  activeColor: categoryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),

          // Timing options (animated, shown when enabled)
          if (hasTimings)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isEnabled
                  ? _TimingRow(
                      label: item.timingLabel!,
                      timingKey: item.timingKey!,
                      options: item.timingOptions!,
                      selectedValue: settings.option(
                        item.timingKey!,
                        item.timingOptions!.first.value,
                      ),
                      color: categoryColor,
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timing row
// ─────────────────────────────────────────────────────────────────────────────

class _TimingRow extends ConsumerWidget {
  final String label;
  final String timingKey;
  final List<_TimingOption> options;
  final String selectedValue;
  final Color color;

  const _TimingRow({
    required this.label,
    required this.timingKey,
    required this.options,
    required this.selectedValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: options.map((opt) {
                final selected = opt.value == selectedValue;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .setOption(timingKey, opt.value);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? color
                            : color.withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : color,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Test notification button
// ─────────────────────────────────────────────────────────────────────────────

class _TestNotificationButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const _TestNotificationButton({
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Надіслати тестове сповіщення',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staggered entry animation
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedEntry({required this.child, required this.index});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: 120 + widget.index * 80);
    Future.delayed(delay, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
