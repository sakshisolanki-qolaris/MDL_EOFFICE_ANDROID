import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({Key? key}) : super(key: key);
  @override
  _DraftsScreenState createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  List<dynamic> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDrafts();
  }

  Future<void> _fetchDrafts() async {
    setState(() => _isLoading = true);
    try {
      // Safely access Dio directly so we don't have to guess your ApiClient methods
      final dio = Provider.of<AuthProvider>(context, listen: false).apiClient.dio;
      final response = await dio.get('/files/drafts');

      if (response.statusCode == 200) {
        setState(() {
          _files = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching drafts: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchDrafts,
      color: AppColors.teal600,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal600))
          : _files.isEmpty
          ? const Center(child: Text('You have no drafts.', style: TextStyle(color: AppColors.slate500, fontSize: 16)))
          : ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];

          final fileNumber = file['fileNumber'] ?? file['file_number'] ?? 'N/A';
          final subject = file['subject'] ?? file['fileSubject'] ?? 'No Subject';
          final priority = file['priority'] ?? 'NORMAL';

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
                // 🟢 Drafts are owned by you, so we allow Actions!
                final Map<String, dynamic> fileData = Map<String, dynamic>.from(file);
                fileData['isReadOnly'] = false;
                Navigator.pushNamed(context, '/files/details', arguments: fileData);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(fileNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal600, fontSize: 14))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: priorityBg, borderRadius: BorderRadius.circular(6)),
                          child: Text(priority, style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.edit_document, size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text('DRAFT - Needs to be forwarded', style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
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