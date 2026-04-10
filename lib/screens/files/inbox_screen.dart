import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);
  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<dynamic> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInbox();
  }

  Future<void> _fetchInbox() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = Provider.of<AuthProvider>(context, listen: false).apiClient;
      final response = await apiClient.getInbox();

      if (response.statusCode == 200) {
        setState(() {
          _files = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchInbox,
      color: AppColors.teal600,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal600))
          : _files.isEmpty
          ? const Center(child: Text('Your inbox is empty.', style: TextStyle(color: AppColors.slate500, fontSize: 16)))
          : ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];

          // 🟢 Safely Extract Data
          final fileNumber = file['fileNumber'] ?? file['file_number'] ?? 'N/A';
          final subject = file['subject'] ?? file['fileSubject'] ?? file['file_subject'] ?? 'No Subject';
          final sender = file['lastSender'] ?? file['last_sender'] ?? file['createdBy'] ?? 'Unknown';
          final senderDesignation = file['sentByDesignation'] ?? 'System';
          final priority = file['priority'] ?? 'NORMAL';

          // Determine Priority Badge Color
          Color priorityColor = AppColors.teal600;
          Color priorityBg = AppColors.teal50;
          if (priority == 'HIGH') {
            priorityColor = Colors.redAccent;
            priorityBg = Colors.red.shade50;
          } else if (priority == 'MEDIUM') {
            priorityColor = Colors.orange.shade700;
            priorityBg = Colors.orange.shade50;
          }

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12)
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // 🟢 Pass the entire file object to the details screen!
                Navigator.pushNamed(context, '/files/details', arguments: file);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TOP ROW: File Number & Priority Badge ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(fileNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal600, fontSize: 14)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: priorityBg, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                              priority,
                              style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold)
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),

                    // --- MIDDLE ROW: Subject ---
                    Text(
                      subject,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // --- BOTTOM ROW: Sender Info ---
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.input_rounded, size: 16, color: AppColors.slate500),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'From: $sender ($senderDesignation)',
                              style: const TextStyle(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}