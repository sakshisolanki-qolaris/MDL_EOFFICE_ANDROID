import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final dio = Provider.of<AuthProvider>(context, listen: false).apiClient.dio;
      final Map<String, dynamic> params = {'limit': 50};
      if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;

      final response = await dio.get('/users', queryParameters: params);

      if (response.statusCode == 200) {
        setState(() {
          _users = response.data['data'] ?? [];
        });
      }
    } on DioException catch (e) {
      print('Fetch Users Error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load users'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 RBAC: Check if current user is ADMIN
    final currentUser = Provider.of<AuthProvider>(context).user;
    final isAdmin = currentUser?['systemRole'] == 'ADMIN';

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: Column(
        children: [
          // --- Search Bar ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.black12))),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by Name or Designation...',
                prefixIcon: const Icon(Icons.search, color: AppColors.slate500),
                filled: true,
                fillColor: AppColors.slate50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // --- User List ---
          Expanded(
            child: RefreshIndicator(
              color: AppColors.teal600,
              onRefresh: _fetchUsers,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal600))
                  : _users.isEmpty
                  ? const Center(child: Text("No users found.", style: TextStyle(color: AppColors.slate500)))
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isActive = user['is_active'] ?? true;
                  final name = user['full_name'] ?? 'Unknown';
                  final designation = user['designation']?['name'] ?? 'No Designation';
                  final department = user['department']?['name'] ?? 'No Dept';
                  final role = user['system_role'] ?? 'STAFF';

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isActive ? AppColors.teal50 : Colors.red.shade50,
                        child: Text(name[0].toUpperCase(), style: TextStyle(color: isActive ? AppColors.teal600 : Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800))),
                          if (!isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                              child: const Text('INACTIVE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('$designation • $department', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                          const SizedBox(height: 4),
                          Text('Role: $role | Phone: ${user['phone_number']}', style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
                        ],
                      ),
                      trailing: const Icon(Icons.edit_square, color: AppColors.slate500, size: 20),
                      onTap: () {
                        // Navigate to Edit Screen
                        Navigator.pushNamed(context, '/users/edit', arguments: user).then((_) => _fetchUsers());
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // 🟢 FAB is ONLY visible to ADMINS!
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        backgroundColor: AppColors.teal600,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('New User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.pushNamed(context, '/users/create').then((_) => _fetchUsers());
        },
      )
          : null,
    );
  }
}