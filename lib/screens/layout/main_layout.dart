import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/sidebar_widget.dart';
import '../../providers/auth_provider.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final String currentRoute;

  const MainLayout({
    Key? key,
    required this.child,
    required this.title,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🟢 Safely read user to get their initial for the top-right avatar
    final user = Provider.of<AuthProvider>(context).user;

    // Check for both camelCase and snake_case matching your backend
    final String fullName = user?['fullName'] ?? 'Official';
    final String initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.slate50,

      // Top Navigation Bar
      appBar: AppBar(
        backgroundColor: AppColors.teal600,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // Show a quick tooltip/snackbar for notifications
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('No new notifications'),
                      duration: Duration(seconds: 1)
                  )
              );
            },
          ),
          GestureDetector(
            onTap: () {
              if (currentRoute != '/profile') {
                Navigator.pushNamed(context, '/profile');
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: CircleAvatar(
                  backgroundColor: AppColors.teal50,
                  radius: 16,
                  child: Text(
                      initial,
                      style: const TextStyle(
                          color: AppColors.teal600,
                          fontSize: 14,
                          fontWeight: FontWeight.bold
                      )
                  ),
                ),
              ),
            ),
          )
        ],
      ),

      // The Dynamic Sidebar we built earlier
      drawer: AppSidebar(currentRoute: currentRoute),

      // The main content of whatever screen is currently active
      body: child,
    );
  }
}