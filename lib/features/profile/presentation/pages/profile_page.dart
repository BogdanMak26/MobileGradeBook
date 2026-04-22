// lib/features/profile/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
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

    final initials = user.fullName.trim().split(' ').take(2)
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
                            const SizedBox(width: 34),
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
                          Text(user.fullName,
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
                    if (user.rank != null || user.position != null) ...[
                      _SectionHeader(
                          icon: Icons.military_tech_rounded,
                          title: 'Посада'),
                      _InfoCard(items: [
                        if (user.rank != null)
                          _InfoRow(
                              icon: Icons.star_outline,
                              label: 'Звання',
                              value: user.rank!),
                        if (user.position != null)
                          _InfoRow(
                              icon: Icons.badge_outlined,
                              label: 'Посада',
                              value: user.position!),
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
                          onTap: () {}),
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

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Вийти?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text('Ви впевнені, що хочете вийти з системи?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authViewModelProvider.notifier).logout();
            },
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
