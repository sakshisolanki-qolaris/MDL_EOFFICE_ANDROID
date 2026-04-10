import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class SearchFilesScreen extends StatefulWidget {
  const SearchFilesScreen({Key? key}) : super(key: key);

  @override
  _SearchFilesScreenState createState() => _SearchFilesScreenState();
}

class _SearchFilesScreenState extends State<SearchFilesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedPriority;
  DateTime? _startDate;
  DateTime? _endDate;

  List<dynamic> _files = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  final List<String> _priorities = ['ALL', 'LOW', 'MEDIUM', 'HIGH'];

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final dio = Provider.of<AuthProvider>(context, listen: false).apiClient.dio;

      // Build Query Parameters
      final Map<String, dynamic> params = {};
      if (_searchController.text.trim().isNotEmpty) {
        params['text'] = _searchController.text.trim();
      }
      if (_selectedPriority != null && _selectedPriority != 'ALL') {
        params['priority'] = _selectedPriority;
      }
      if (_startDate != null) {
        params['startDate'] = _startDate!.toIso8601String().split('T')[0];
      }
      if (_endDate != null) {
        params['endDate'] = _endDate!.toIso8601String().split('T')[0];
      }

      final response = await dio.get('/files/search', queryParameters: params);

      if (response.statusCode == 200) {
        setState(() {
          _files = response.data['data'] ?? [];
        });
      }
    } on DioException catch (e) {
      print('Search Error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to search files. Check your connection.'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedPriority = null;
      _startDate = null;
      _endDate = null;
      _files = [];
      _hasSearched = false;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal600,
              onPrimary: Colors.white,
              onSurface: AppColors.slate800,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Ensure end date isn't before start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: Column(
        children: [
          // --- SEARCH FILTERS SECTION ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.black12))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Subject or File Number...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.slate500),
                    filled: true,
                    fillColor: AppColors.slate50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    // PRIORITY DROPDOWN
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedPriority,
                            hint: const Text('Priority', style: TextStyle(fontSize: 14)),
                            icon: const Icon(Icons.flag, size: 16, color: AppColors.slate500),
                            items: _priorities.map((String priority) {
                              return DropdownMenuItem<String>(
                                value: priority,
                                child: Text(priority, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() => _selectedPriority = newValue);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // DATE RANGE BUTTON
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: () async {
                          await _selectDate(context, true);
                          if (_startDate != null && mounted) {
                            await _selectDate(context, false);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.slate50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.date_range, size: 16, color: AppColors.slate500),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _startDate != null && _endDate != null
                                      ? '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}'
                                      : 'Date Range',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: _startDate != null ? AppColors.teal600 : AppColors.slate500,
                                      fontWeight: _startDate != null ? FontWeight.bold : FontWeight.normal
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear, size: 16, color: AppColors.slate500),
                        label: const Text('Clear', style: TextStyle(color: AppColors.slate500)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal600,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        onPressed: _performSearch,
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text('Search Files', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),

          // --- RESULTS SECTION ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal600))
                : !_hasSearched
                ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text("Enter criteria above to search files.", style: TextStyle(color: AppColors.slate500)),
                  ],
                )
            )
                : _files.isEmpty
                ? const Center(child: Text("No files match your search criteria.", style: TextStyle(color: AppColors.slate500)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];

                final fileNumber = file['fileNumber'] ?? file['file_number'] ?? 'N/A';
                final subject = file['subject'] ?? file['fileSubject'] ?? 'No Subject';
                final currentHolder = file['currentHolder'] ?? 'Pending Assignment';

                // Safely extract the position of the file
                final fileDesig = file['currentPosition']?['designation'] ?? file['currentDesignation'] ?? 'Unknown';
                final fileDept = file['currentPosition']?['department'] ?? file['currentDepartment'] ?? 'Unknown';

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
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // 🟢 DYNAMIC INBOX vs OUTBOX CALCULATION (Shared Desk Fix)
                      // 1. Get the currently logged-in user's exact desk (Position)
                      final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
                      final String userDept = currentUser?['department'] ?? '';
                      final String userDesig = currentUser?['designation'] ?? '';

                      // 2. The Magic Rule: If the file is on YOUR desk, it acts like your Inbox!
                      bool isReadOnly = true;
                      if (userDept == fileDept && userDesig == fileDesig) {
                        isReadOnly = false; // Match! Action Allowed.
                      }

                      // Add the flag to the file data
                      final Map<String, dynamic> fileData = Map<String, dynamic>.from(file);
                      fileData['isReadOnly'] = isReadOnly;

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
                          Text(subject, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate800, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.slate500),
                              const SizedBox(width: 6),
                              Expanded(child: Text('With: $currentHolder ($fileDesig)', style: const TextStyle(color: AppColors.slate500, fontSize: 12))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}