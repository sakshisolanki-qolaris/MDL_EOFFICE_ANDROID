import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../api/api_config.dart';


class FileDetailsScreen extends StatefulWidget {
  @override
  _FileDetailsScreenState createState() => _FileDetailsScreenState();
}


class _FileDetailsScreenState extends State<FileDetailsScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic> _fileData = {};
  List<dynamic> _history = [];
  List<dynamic> _attachments = [];
  bool _isLoading = true;
  int _fileId = 0;
  bool _isReadOnly = false;
  bool _isInit = false;
  String? _minioBaseUrl; // 🟢 Added to store dynamic host
  late TabController _tabController;
  final ScrollController _timelineScrollController = ScrollController(); // 🟢 Added controller



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // 🟢 Listen for tab changes to trigger auto-scroll
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        _scrollToBottom();
      }
    });
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_timelineScrollController.hasClients) {
        _timelineScrollController.animateTo(
          _timelineScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }


  @override
  void dispose() {
    _tabController.dispose();
    _timelineScrollController.dispose(); // 🟢 Dispose controller
    super.dispose();
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map) {
        _fileData = Map<String, dynamic>.from(args);
        _fileId = _fileData['id'] ?? _fileData['fileId'] ?? 0;
        _isReadOnly = _fileData['isReadOnly'] ?? false;
        
        // 🟢 Fetch MinIO Base URL once
        ApiConfig.getMinioUrl().then((url) {
          if (mounted) setState(() => _minioBaseUrl = url);
        });

        if (_fileId != 0) {
          _fetchFileHistory();
        } else {
          setState(() => _isLoading = false);
        }
      } else {

        setState(() => _isLoading = false);
      }
      _isInit = true;
    }
  }

  Future<void> _fetchFileHistory() async {
    try {
      final apiClient = Provider.of<AuthProvider>(context, listen: false).apiClient;
      final response = await apiClient.getFileHistory(_fileId);

      if (response.statusCode == 200) {
        setState(() {
          final data = response.data['data'];

          if (data is Map) {
            _history = data['history'] ?? data['movements'] ?? data['thread'] ?? [];
            final backendFile = data['fileInfo'] ?? data['file'] ?? data;

            if (backendFile is Map) {
              backendFile.forEach((key, value) {
                if (value != null) _fileData[key] = value;
              });
            }

            _attachments = [];
            for (var move in _history) {
              if (move['attachments'] != null && move['attachments'] is List) {
                _attachments.addAll(move['attachments']);
              }
            }
          } else if (data is List) {
            _history = data;
          }
          _isLoading = false;
        });
        
        // 🟢 Scroll after data is fetched and rendered
        _scrollToBottom();
      }

    } on DioException catch (e) {
      print("History Error: ${e.message}");
      setState(() => _isLoading = false);
    }
  }

  String _extractName(dynamic userObj, String fallback) {
    if (userObj == null) return fallback;
    if (userObj is String) return userObj;
    if (userObj is Map) return userObj['fullName'] ?? userObj['full_name'] ?? fallback;
    return fallback;
  }

  String? _buildMinioUrl(String? path) {
    if (path == null || path.isEmpty || _minioBaseUrl == null) return null;
    
    // If it's already a full URL, just ensure the host is correct
    if (path.startsWith('http')) {
       // Replace localhost or 10.0.2.2 with the dynamically detected host
       return path.replaceAll('localhost', '127.0.0.1').replaceAll('10.0.2.2', '127.0.0.1')
                  .replaceAll('127.0.0.1', _minioBaseUrl!.contains('10.0.2.2') ? '10.0.2.2' : '127.0.0.1');
    }
    
    return '$_minioBaseUrl/e-office-files/$path';
  }


  Future<void> _openAttachment(Map<String, dynamic> attachment) async {
    final attachmentId = attachment['id'];
    final fileName = attachment['fileName'] ?? attachment['file_name'] ?? attachment['name'] ?? 'document.pdf';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading $fileName...'), duration: const Duration(seconds: 1)));

    try {
      final apiClient = Provider.of<AuthProvider>(context, listen: false).apiClient;
      final response = await apiClient.downloadAttachment(attachmentId);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(response.data);

      final result = await OpenFilex.open(tempFile.path);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No app found to open this file.'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download attachment.'), backgroundColor: Colors.redAccent));
    }
  }

  // --- BOTTOM SHEET ACTION FORM ---
  void _showForwardBottomSheet() {
    final _remarkController = TextEditingController();
    final _pinController = TextEditingController();
    final _receiverSearchController = TextEditingController();

    bool _isSubmitting = false;
    bool _obscurePin = true; // 🟢 Added state for visibility


    // 🟢 NEW: List to hold multiple files
    List<PlatformFile> _selectedFiles = [];

    Timer? _debounce;
    bool _isSearching = false;
    List<dynamic> _searchResults = [];
    int? _selectedReceiverId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {

          void _onSearchChanged(String query) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();

            if (query.isEmpty) {
              setModalState(() { _searchResults = []; _selectedReceiverId = null; });
              return;
            }

            _debounce = Timer(const Duration(milliseconds: 500), () async {
              setModalState(() => _isSearching = true);
              try {
                final dio = Provider.of<AuthProvider>(context, listen: false).apiClient.dio;
                final res = await dio.get('/users', queryParameters: {'search': query, 'limit': 5});

                if (res.statusCode == 200) {
                  setModalState(() {
                    _searchResults = res.data['data'] ?? [];
                    _isSearching = false;
                  });
                }
              } catch (e) {
                setModalState(() { _searchResults = []; _isSearching = false; });
              }
            });
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Action File', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.slate800)),
                const SizedBox(height: 16),

                TextField(
                    controller: _receiverSearchController,
                    onChanged: (val) {
                      _selectedReceiverId = null;
                      _onSearchChanged(val);
                    },
                    decoration: InputDecoration(
                        labelText: 'Search Receiver Name...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.search, color: AppColors.slate500),
                        suffixIcon: _isSearching
                            ? const SizedBox(width: 16, height: 16, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal600)))
                            : (_selectedReceiverId != null ? const Icon(Icons.check_circle, color: AppColors.green600) : null)
                    )
                ),

                if (_searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final name = user['full_name'] ?? 'Unknown';
                        final designation = user['designation']?['name'] ?? 'Staff';
                        final department = user['department']?['name'] ?? '';

                        return ListTile(
                          leading: CircleAvatar(backgroundColor: AppColors.teal50, child: Text(name[0], style: const TextStyle(color: AppColors.teal600, fontWeight: FontWeight.bold))),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('$designation - $department', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                          onTap: () {
                            setModalState(() {
                              _selectedReceiverId = user['id'];
                              _receiverSearchController.text = '$name ($designation)';
                              _searchResults = [];
                            });
                          },
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),
                TextField(controller: _remarkController, maxLines: 3, decoration: InputDecoration(labelText: 'Remarks / Comments', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 16),

                // 🟢 MULTIPLE FILE UPLOAD UI
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.slate50, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedFiles.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedFiles.map((file) {
                            return Chip(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              label: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 180),
                                child: Text(file.name, style: const TextStyle(fontSize: 12, color: AppColors.slate800), overflow: TextOverflow.ellipsis),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                              onDeleted: () => setModalState(() => _selectedFiles.remove(file)),
                            );
                          }).toList(),
                        ),
                      if (_selectedFiles.isNotEmpty) const SizedBox(height: 8),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate800, elevation: 0),
                        onPressed: () async {
                          // Allow picking multiple files
                          FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
                          if (result != null) {
                            setModalState(() {
                              // Prevent exceeding your backend's 10 file limit
                              if (_selectedFiles.length + result.files.length > 10) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can only attach a maximum of 10 files.'), backgroundColor: Colors.orange));
                              } else {
                                _selectedFiles.addAll(result.files);
                              }
                            });
                          }
                        },
                        icon: const Icon(Icons.attach_file, size: 16),
                        label: Text(_selectedFiles.isEmpty ? 'Attach Files' : 'Add More Files'),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                    controller: _pinController,
                    obscureText: _obscurePin,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'Enter 4-Digit PIN to Sign',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: AppColors.slate500),
                          onPressed: () => setModalState(() => _obscurePin = !_obscurePin),
                        )
                    )
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () async {
                      if (_selectedReceiverId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please search and select a Receiver from the list.'), backgroundColor: Colors.orange));
                        return;
                      }

                      setModalState(() => _isSubmitting = true);
                      try {
                        final formData = FormData();

                        formData.fields.add(MapEntry('receiverId', _selectedReceiverId.toString()));
                        formData.fields.add(MapEntry('remarks', _remarkController.text));
                        formData.fields.add(MapEntry('pin', _pinController.text));

                        // 🟢 LOOP THROUGH ALL FILES AND ADD THEM TO MULTIPART
                        if (_selectedFiles.isNotEmpty) {
                          for (var file in _selectedFiles) {
                            if (file.path != null) {
                              formData.files.add(MapEntry(
                                  'attachments', // Must exactly match upload.array("attachments")
                                  await MultipartFile.fromFile(file.path!, filename: file.name)
                              ));
                            }
                          }
                        }

                        await Provider.of<AuthProvider>(context, listen: false).apiClient.moveFile(_fileId, formData);

                        Navigator.pop(context); // 1. Close the Bottom Sheet
                        Navigator.pushReplacementNamed(context, '/files/outbox'); // 2. Go directly to Outbox!
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File forwarded successfully!'), backgroundColor: AppColors.green600));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to forward. Check your PIN.'), backgroundColor: Colors.redAccent));
                        setModalState(() => _isSubmitting = false);
                      }
                    },
                    child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign & Forward', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(appBar: AppBar(backgroundColor: AppColors.teal600), body: const Center(child: CircularProgressIndicator(color: AppColors.teal600)));

    final String fileNumber = _fileData['fileNumber'] ?? _fileData['file_number'] ?? 'File Details';
    final String subject = _fileData['subject'] ?? _fileData['fileSubject'] ?? _fileData['file_subject'] ?? 'No Subject Provided';
    final String priority = _fileData['priority'] ?? _fileData['filePriority'] ?? 'NORMAL';
    final String status = _fileData['status'] ?? 'ACTIVE';

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: AppColors.teal600,
        elevation: 0,
        title: Text(fileNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Timeline'),
            Tab(text: 'Files'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- TAB 1: OVERVIEW ---
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoCard('Subject', subject, Icons.subject),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildInfoCard('Priority', priority, Icons.flag, isPriority: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInfoCard('Status', status, Icons.info_outline)),
                  ],
                ),
              ],
            ),
          ),

          // --- TAB 2: COMPACT TIMELINE WITH INLINE ATTACHMENTS ---
          SingleChildScrollView(
            controller: _timelineScrollController, // 🟢 Attach controller
            padding: const EdgeInsets.all(16),
            child: _history.isEmpty

                ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("No movement history yet.", style: TextStyle(color: AppColors.slate500))))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final move = _history[index];
                final senderName = _extractName(move['sender'], 'System');
                final receiverName = _extractName(move['receiver'], 'Pending');
                final rawSignature = move['senderSignature'] ?? move['signatureUrl'] ?? move['signature_url'];
                final fullSignatureUrl = _buildMinioUrl(rawSignature);

                final List<dynamic> moveAttachments = move['attachments'] ?? [];

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                          children: [
                            Container(
                                width: 12, height: 12,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(color: index == 0 ? AppColors.teal600 : Colors.grey.shade400, shape: BoxShape.circle)
                            ),
                            if (index != _history.length - 1)
                              Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
                          ]
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(senderName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate800)),
                                        Text('→ $receiverName', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                                      ],
                                    ),
                                  ),
                                  if (move['date'] != null)
                                    Text(
                                      move['date'].toString().replaceAll(',', '\n'),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontSize: 9, color: AppColors.slate500, fontWeight: FontWeight.bold),
                                    ),


                                ],
                              ),

                              if (move['remarks'] != null && move['remarks'].toString().isNotEmpty)
                                Stack(
                                  children: [
                                    Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 25), // Extra bottom padding for signature
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade200),
                                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
                                        ),

                                        child: Text('"${move['remarks']}"', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700, fontSize: 13))
                                    ),
                                    if (fullSignatureUrl != null)
                                      Positioned(
                                        bottom: 2,
                                        right: 8,
                                        child: SizedBox(
                                          height: 35, width: 80,
                                          child: Image.network(
                                              fullSignatureUrl,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) => const Text('[No Sig]', style: TextStyle(fontSize: 9, color: Colors.redAccent))
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                              if (moveAttachments.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: moveAttachments.map((att) {
                                      final attName = att['fileName'] ?? att['name'] ?? att['original_name'] ?? 'Document.pdf';
                                      return InkWell(
                                        onTap: () => _openAttachment(att),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                              color: AppColors.teal50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.teal.shade100)
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.picture_as_pdf, size: 14, color: Colors.redAccent),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                    attName,
                                                    style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                                                    overflow: TextOverflow.ellipsis
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),

          // --- TAB 3: ALL ATTACHMENTS (GLOBAL) ---
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _attachments.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("No attachments found for this file.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.slate500))))
                : ListView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _attachments.length,
              itemBuilder: (context, index) {
                final attachment = _attachments[index];
                final fileName = attachment['fileName'] ?? attachment['name'] ?? attachment['original_name'] ?? 'Document ${index + 1}.pdf';

                return Card(
                  elevation: 0, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent)),
                    title: Text(fileName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate800)),
                    subtitle: const Text('Tap to download & view', style: TextStyle(fontSize: 12)),
                    trailing: IconButton(icon: const Icon(Icons.download_rounded, color: AppColors.teal600), onPressed: () => _openAttachment(attachment)),
                    onTap: () => _openAttachment(attachment),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: _isReadOnly ? null : FloatingActionButton.extended(
        backgroundColor: AppColors.teal600,
        icon: const Icon(Icons.send, color: Colors.white),
        label: const Text('Action File', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          // 🟢 1. Check if PIN is set BEFORE opening the bottom sheet
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final isPinSet = authProvider.user?['isPinSet'] ?? false;

          if (!isPinSet) {
            // Show Warning
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Action Required: Please set your Security PIN before forwarding files.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );

            // Redirect to Set PIN Screen
            Navigator.pushNamed(context, '/auth/set-pin');
          } else {
            // 🟢 2. If PIN is set, open the bottom sheet normally!
            _showForwardBottomSheet();
          }
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, {bool isPriority = false}) {
    Color valueColor = AppColors.slate800;
    if (isPriority) valueColor = value.toUpperCase() == 'HIGH' ? Colors.redAccent : (value.toUpperCase() == 'MEDIUM' ? Colors.orange : AppColors.teal600);
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 16, color: AppColors.slate500), const SizedBox(width: 8), Text(title, style: const TextStyle(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8), Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}