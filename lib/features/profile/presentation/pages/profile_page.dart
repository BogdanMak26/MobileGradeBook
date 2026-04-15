// lib/features/profile/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authViewModelProvider);
    final user = auth.role == 'CADET'
        ? MockDataProvider.cadetUser
        : MockDataProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Профіль')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.loginGradientStart, AppTheme.loginGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      user.surname[0],
                      style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.fullName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      UserRole.displayName(auth.role ?? ''),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Info cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.rank != null || user.position != null) ...[
                    _SectionTitle('Посада'),
                    _InfoCard(items: [
                      if (user.rank != null)
                        _InfoItem(label: 'Звання', value: user.rank!),
                      if (user.position != null)
                        _InfoItem(label: 'Посада', value: user.position!),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  if (user.kafedraName != null) ...[
                    _SectionTitle('Підрозділ'),
                    _InfoCard(items: [
                      _InfoItem(label: 'Кафедра', value: user.kafedraName!),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  if (user.groupName != null) ...[
                    _SectionTitle('Навчання'),
                    _InfoCard(items: [
                      _InfoItem(label: 'Група', value: user.groupName!),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  _SectionTitle('Контакти'),
                  _InfoCard(items: [
                    _InfoItem(label: 'Email', value: user.email),
                  ]),
                  const SizedBox(height: 16),

                  // Settings
                  _SectionTitle('Налаштування'),
                  _SettingsCard(items: [
                    _SettingsItem(
                        icon: Icons.notifications_outlined,
                        label: 'Сповіщення',
                        onTap: () {}),
                    _SettingsItem(
                        icon: Icons.language,
                        label: 'Мова',
                        trailing: 'Українська',
                        onTap: () {}),
                    _SettingsItem(
                        icon: Icons.info_outline,
                        label: 'Про застосунок',
                        trailing: 'v1.0.0',
                        onTap: () {}),
                  ]),
                  const SizedBox(height: 12),

                  // Logout
                  _SettingsCard(items: [
                    _SettingsItem(
                        icon: Icons.logout,
                        label: 'Вийти',
                        labelColor: const Color(0xFFDC2626),
                        iconColor: const Color(0xFFDC2626),
                        onTap: () => _confirmLogout(context, ref)),
                  ]),
                  const SizedBox(height: 24),
                ],
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
        title: const Text('Вийти?'),
        content: const Text('Ви впевнені, що хочете вийти з системи?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Скасувати')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authViewModelProvider.notifier).logout();
            },
            child: const Text('Вийти',
                style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMid)),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.value.label,
                        style: const TextStyle(
                            color: AppTheme.textMid, fontSize: 14)),
                    Text(e.value.value,
                        style: const TextStyle(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w500,
                            fontSize: 14)),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String? trailing;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.labelColor,
    this.iconColor,
    required this.onTap,
  });
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              ListTile(
                onTap: item.onTap,
                leading: Icon(item.icon,
                    color: item.iconColor ?? AppTheme.textMid, size: 20),
                title: Text(item.label,
                    style: TextStyle(
                        color: item.labelColor ?? AppTheme.textDark,
                        fontSize: 14)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.trailing != null)
                      Text(item.trailing!,
                          style: const TextStyle(
                              color: AppTheme.textMid, fontSize: 13)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        color: AppTheme.textLight, size: 18),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}
