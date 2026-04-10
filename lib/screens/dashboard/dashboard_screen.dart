import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../layout/main_layout.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  int _inboxCount = 0;
  int _outboxCount = 0;
  int _draftsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final apiClient = Provider.of<AuthProvider>(context, listen: false).apiClient;

      // We only need the count, so we limit the data payload to 1 item to save bandwidth
      final responses = await Future.wait([
        apiClient.getInbox(limit: 1),
        apiClient.getOutbox(limit: 1),
        apiClient.getDrafts(limit: 1),
      ]);

      if (mounted) {
        setState(() {
          _inboxCount = responses[0].data['count'] ?? 0;
          _outboxCount = responses[1].data['count'] ?? 0;
          _draftsCount = responses[2].data['count'] ?? 0;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      print("Dashboard Stats Error: ${e.message}");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.slate800)),
            ],
          ),
          Text(title, style: const TextStyle(fontSize: 14, color: AppColors.slate500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get real user name from AuthProvider
    final user = Provider.of<AuthProvider>(context).user;
    final String firstName = (user?['fullName'] ?? 'User').split(' ')[0];

    return MainLayout(
      title: 'Dashboard',
      currentRoute: '/dashboard',
      child: RefreshIndicator(
        onRefresh: _fetchDashboardStats,
        color: AppColors.teal600,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back, $firstName 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.slate800)),
              const SizedBox(height: 4),
              const Text('Here is what is happening with your files today.', style: TextStyle(color: AppColors.slate500)),
              const SizedBox(height: 24),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.teal600)),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard('Pending Inbox', '$_inboxCount', Icons.inbox, AppColors.teal600),
                    _buildStatCard('Sent Outbox', '$_outboxCount', Icons.send, Colors.blue),
                    _buildStatCard('Drafts', '$_draftsCount', Icons.description, Colors.purple),
                    _buildStatCard('Completed', '0', Icons.check_circle, AppColors.green500),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}