import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class AppSidebar extends StatelessWidget {
  final String currentRoute;

  const AppSidebar({required this.currentRoute});

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.teal600 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : AppColors.slate500, size: 20),
        title: Text(title, style: TextStyle(color: isActive ? Colors.white : AppColors.slate500, fontWeight: FontWeight.w600)),
        onTap: () {
          Navigator.pop(context);
          if (!isActive) Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // 🟢 Perfectly matched to UserResponseDto.js
    final String role = user?['systemRole'] ?? '';
    final String designation = user?['designation'] ?? 'Staff';
    final String fullName = user?['fullName'] ?? user?['full_name'] ?? 'Official';

    final bool isStaff = role == 'STAFF';
    final bool isAdmin = role == 'ADMIN';
    final bool isBoardMember = role == 'BOARD_MEMBER';
    final bool isPresident = designation == 'PRESIDENT';

    final canCreateFiles = isStaff || isAdmin || isBoardMember;
    final canSetPin = isAdmin || isBoardMember;
    final canManageUsers = isAdmin || isPresident;

    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';

    return Drawer(
      backgroundColor: AppColors.slate900,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.slate800))),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('e-Office', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('MAHARASHTRA MANDAL', style: TextStyle(color: AppColors.slate500, fontSize: 10, letterSpacing: 1)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildNavItem(context, Icons.dashboard, 'Dashboard', '/dashboard', currentRoute == '/dashboard'),
                _buildNavItem(context, Icons.inbox, 'Inbox', '/inbox', currentRoute == '/inbox'),
                _buildNavItem(context, Icons.edit_document, 'Drafts', '/files/drafts', currentRoute == '/files/drafts'),
                _buildNavItem(context, Icons.send, 'Outbox', '/files/outbox', currentRoute == '/files/outbox'),
                _buildNavItem(context, Icons.search, 'Search Files', '/files/search', currentRoute == '/files/search'),

                const Divider(color: AppColors.slate800, indent: 16, endIndent: 16, height: 32),

                if (canCreateFiles)
                  _buildNavItem(context, Icons.add_circle_outline, 'Initiate File', '/files/create', currentRoute == '/files/create'),

                if (canSetPin)
                  _buildNavItem(context, Icons.security, 'Set PIN', '/auth/set-pin', currentRoute == '/auth/set-pin'),

                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.user;
                    final isManager = user?['systemRole'] == 'ADMIN' || user?['designation'] == 'PRESIDENT';

                    if (isManager) {
                      return _buildNavItem(context, Icons.people_alt, 'Manage Users', '/users', currentRoute == '/users');
                    }
                    return const SizedBox.shrink(); // Hide if regular staff
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.slate900, border: Border(top: BorderSide(color: AppColors.slate800))),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.slate800, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate500.withOpacity(0.2))),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: AppColors.teal600, radius: 18, child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                            Text(designation, style: const TextStyle(color: AppColors.slate500, fontSize: 11), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (Route<dynamic> route) => false);
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent, size: 16),
                  label: const Text('SIGN OUT', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}