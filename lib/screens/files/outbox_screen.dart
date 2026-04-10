import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class OutboxScreen extends StatefulWidget {
  const OutboxScreen({Key? key}) : super(key: key);

  @override
  _OutboxScreenState createState() => _OutboxScreenState();
}

class _OutboxScreenState extends State<OutboxScreen> {
  List<dynamic> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOutbox();
  }

  Future<void> _fetchOutbox() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = Provider.of<AuthProvider>(context, listen: false).apiClient;
      final response = await apiClient.getOutbox();

      if (response.statusCode == 200) {
        setState(() {
          _files = response.data['data'] ?? [];
        });
      }
    } on DioException catch (e) {
      print('Fetch Outbox Error: ${e.message}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchOutbox,
      color: AppColors.teal600,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal600))
          : _files.isEmpty
          ? const Center(child: Text('Your outbox is empty.', style: TextStyle(color: AppColors.slate500, fontSize: 16)))
          : ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];

          // Safely extract data from the backend JSON
          final fileNumber = file['fileNumber'] ?? file['file_number'] ?? 'N/A';
          final subject = file['subject'] ?? file['fileSubject'] ?? 'No Subject';
          final currentHolder = file['currentHolder'] ?? 'Pending Assignment';
          final currentPosition = file['currentPosition']?['designation'] ?? file['currentDesignation'] ?? 'Unknown';

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // 🟢 Create a copy of the file map and add a READ ONLY flag
                final Map<String, dynamic> fileData = Map<String, dynamic>.from(file);
                fileData['isReadOnly'] = true; // Tell the details screen to hide the Action button!

                Navigator.pushNamed(context, '/files/details', arguments: fileData);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(fileNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal600, fontSize: 14)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: const Text('SENT', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(subject, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate800, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: AppColors.slate500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('Currently with: $currentHolder ($currentPosition)', style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
                        ),
                      ],
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