import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Core
import 'core/theme/app_colors.dart';
import 'api/api_client.dart';
import 'providers/auth_provider.dart';

// Layout & Screens
import 'screens/layout/main_layout.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/set_pin_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/files/inbox_screen.dart';
import 'screens/files/outbox_screen.dart';
import 'screens/files/create_file_screen.dart';
import 'screens/files/file_details_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/users/manage_users_screen.dart';
import 'screens/users/create_edit_user_screen.dart';
import 'screens/files/drafts_screen.dart';
import 'screens/profile/profile_screen.dart';

import 'api/api_config.dart';
import 'core/navigation/navigator_service.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  final baseUrl = await ApiConfig.getBaseUrl();
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  const secureStorage = FlutterSecureStorage();
  final apiClient = ApiClient(dio: dio, secureStorage: secureStorage);


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            apiClient: apiClient,
            secureStorage: secureStorage,
          ),
        ),
      ],
      child: const EOfficeApp(),
    ),
  );
}

class EOfficeApp extends StatelessWidget {

  const EOfficeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🟢 Notice we REMOVED the Consumer from wrapping the MaterialApp
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'eOffice Maharashtra Mandal',

      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: AppColors.teal600,
        scaffoldBackgroundColor: AppColors.slate50,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // 🟢 The Consumer now ONLY wraps the home screen.
      // This dynamically swaps between Loading -> Login -> Dashboard safely.
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.teal600),
              ),
            );
          }

          return authProvider.isAuthenticated
              ? DashboardScreen()
              : LoginScreen();
        },
      ),

      // 🟢 Do NOT use initialRoute here. Just define the named routes.
      routes: {
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/inbox': (context) => MainLayout(title: 'Inbox', currentRoute: '/inbox', child: InboxScreen()),
        '/files/drafts': (context) => const MainLayout(title: 'Drafts', currentRoute: '/files/drafts', child: DraftsScreen()),
        '/files/outbox': (context) => MainLayout(title: 'Outbox', currentRoute: '/files/outbox', child: OutboxScreen()),
        '/files/create': (context) => MainLayout(title: 'Initiate File', currentRoute: '/files/create', child: CreateFileScreen()),
        '/files/search': (context) => MainLayout(title: 'Search Files', currentRoute: '/files/search', child: SearchFilesScreen()),
        '/files/details': (context) => FileDetailsScreen(),
        '/auth/set-pin': (context) => MainLayout(title: 'Set PIN', currentRoute: '/auth/set-pin', child: SetPinScreen()),
        '/users': (context) => const MainLayout(title: 'Manage Users', currentRoute: '/users', child: ManageUsersScreen()),
        '/users/create': (context) => const CreateEditUserScreen(), // Doesn't need sidebar layout
        '/profile': (context) => const MainLayout(title: 'User Profile', currentRoute: '/profile', child: ProfileScreen()),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/users/edit') {
          final user = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CreateEditUserScreen(userToEdit: user),
          );
        }
        return null;
      },
    );
  }
}