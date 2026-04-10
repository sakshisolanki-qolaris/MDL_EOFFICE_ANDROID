import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class CreateEditUserScreen extends StatefulWidget {
  final Map<String, dynamic>? userToEdit; // Null if creating, populated if editing

  const CreateEditUserScreen({Key? key, this.userToEdit}) : super(key: key);

  @override
  _CreateEditUserScreenState createState() => _CreateEditUserScreenState();
}

class _CreateEditUserScreenState extends State<CreateEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<dynamic> _departments = [];
  List<dynamic> _designations = [];

  // Form Fields
  String _fullName = '';
  String _phoneNumber = '';
  String _email = '';
  String _password = '';
  String _systemRole = 'STAFF';
  int? _departmentId;
  int? _designationId;
  bool _isActive = true;
  PlatformFile? _signatureFile;

  bool get _isEditMode => widget.userToEdit != null;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
    if (_isEditMode) {
      final u = widget.userToEdit!;
      _fullName = u['full_name'] ?? '';
      _phoneNumber = u['phone_number'] ?? '';
      _email = u['email'] ?? '';
      _systemRole = u['system_role'] ?? 'STAFF';
      _departmentId = u['department']?['id'];
      _designationId = u['designation']?['id'];
      _isActive = u['is_active'] ?? true;
    }
  }

  Future<void> _fetchDropdownData() async {
    try {
      final dio = Provider.of<AuthProvider>(context, listen: false).apiClient.dio;
      // Fetch both simultaneously to save time
      final responses = await Future.wait([
        dio.get('/users/departments'),
        dio.get('/users/designations'),
      ]);

      if (mounted) {
        setState(() {
          _departments = responses[0].data['data'] ?? [];
          _designations = responses[1].data['data'] ?? [];

          // Fallbacks in case ID is deleted/invalid
          if (_departmentId != null && !_departments.any((d) => d['id'] == _departmentId)) _departmentId = null;
          if (_designationId != null && !_designations.any((d) => d['id'] == _designationId)) _designationId = null;

          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load form data.'), backgroundColor: Colors.redAccent));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (!_isEditMode && _signatureFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please attach a signature image.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = Provider.of<AuthProvider>(context, listen: false).apiClient.dio;

      if (_isEditMode) {
        // --- PATCH (UPDATE USER) ---
        final Map<String, dynamic> data = {
          "fullName": _fullName,
          "email": _email.isNotEmpty ? _email : null,
          "systemRole": _systemRole,
          "designationId": _designationId,
          "departmentId": _departmentId,
          "isActive": _isActive,
        };
        // Only send password if they typed a new one
        if (_password.isNotEmpty) data["password"] = _password;

        await dio.patch('/users/${widget.userToEdit!['id']}', data: data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated successfully!'), backgroundColor: AppColors.green600));
      } else {
        // --- POST (CREATE USER) ---
        final formData = FormData.fromMap({
          "fullName": _fullName,
          "phoneNumber": _phoneNumber,
          "email": _email,
          "password": _password,
          "systemRole": _systemRole,
          "designationId": _designationId,
          "departmentId": _departmentId,
        });

        if (_signatureFile != null && _signatureFile!.path != null) {
          formData.files.add(MapEntry(
              'signature', // Matches uploadSignature.single("signature") in Node.js
              await MultipartFile.fromFile(_signatureFile!.path!, filename: _signatureFile!.name)
          ));
        }

        await dio.post('/users', data: formData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created successfully!'), backgroundColor: AppColors.green600));
      }

      Navigator.pop(context); // Go back to list
    } on DioException catch (e) {
      String errMsg = 'An error occurred';
      if (e.response != null && e.response?.data != null) {
        errMsg = e.response?.data['message'] ?? errMsg;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.teal600)));
    }

    final currentUser = Provider.of<AuthProvider>(context).user;
    final isAdmin = currentUser?['systemRole'] == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit User' : 'Create New User', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.teal600,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info
              TextFormField(
                initialValue: _fullName,
                decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                onSaved: (val) => _fullName = val!.trim(),
              ),
              const SizedBox(height: 16),

              // Phone (Disabled on Edit based on your backend rules)
              TextFormField(
                initialValue: _phoneNumber,
                enabled: !_isEditMode,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number (Login ID)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: _isEditMode, fillColor: _isEditMode ? Colors.grey.shade100 : null,
                ),
                validator: (val) {
                  if (_isEditMode) return null;
                  if (val == null || !RegExp(r"^[6-9]\d{9}$").hasMatch(val)) return 'Enter valid 10-digit Indian number';
                  return null;
                },
                onSaved: (val) => _phoneNumber = val!.trim(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email (Optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                onSaved: (val) => _email = val!.trim(),
              ),
              const SizedBox(height: 16),

              if (!_isEditMode) ...[
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    helperText: '8-16 chars, 1 Uppercase, 1 Number, 1 Special Char',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password is required';
                    if (!RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9])(?!.*\s).{8,16}$").hasMatch(val)) {
                      return 'Password does not meet requirements';
                    }
                    return null;
                  },
                  onSaved: (val) => _password = val ?? '',
                ),
                const SizedBox(height: 16),
              ],
              const Divider(height: 48),

              // Role & Positions
              const Text('Position & Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800)),
              const SizedBox(height: 16),

              // Only Admins can change System Roles
              DropdownButtonFormField<String>(
                value: _systemRole,
                decoration: InputDecoration(
                    labelText: 'System Role',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))
                ),
                // 🟢 1. Only show 'ADMIN' in the list if the current user is an Admin
                items: ['ADMIN', 'STAFF', 'BOARD_MEMBER']
                    .where((role) => role != 'ADMIN' || isAdmin)
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                // 🟢 2. Allow anyone who reached this page (Admin or President) to change it
                onChanged: (val) => setState(() => _systemRole = val!),
                onSaved: (val) => _systemRole = val!,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _departmentId,
                decoration: InputDecoration(labelText: 'Department', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: _departments.map<DropdownMenuItem<int>>((d) => DropdownMenuItem<int>(value: d['id'], child: Text(d['name']))).toList(),
                validator: (val) => val == null ? 'Required' : null,
                onChanged: (val) => setState(() => _departmentId = val),
                onSaved: (val) => _departmentId = val,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _designationId,
                decoration: InputDecoration(labelText: 'Designation', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: _designations.map<DropdownMenuItem<int>>((d) => DropdownMenuItem<int>(value: d['id'], child: Text(d['name']))).toList(),
                validator: (val) => val == null ? 'Required' : null,
                onChanged: (val) => setState(() => _designationId = val),
                onSaved: (val) => _designationId = val,
              ),
              const SizedBox(height: 16),

              // Signature Upload (Only on Create)
              if (!_isEditMode) ...[
                const SizedBox(height: 16),
                const Text('Signature Image (*Required)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),

                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    // Open the gallery to pick an image
                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                    if (result != null) {
                      setState(() => _signatureFile = result.files.first);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120, // Tall enough to see the signature clearly
                    decoration: BoxDecoration(
                        color: AppColors.slate50,
                        border: Border.all(color: _signatureFile != null ? AppColors.teal600 : Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(12)
                    ),
                    // If we have a file, show the Image! Otherwise, show the Upload Icon.
                    child: _signatureFile != null && _signatureFile!.path != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_signatureFile!.path!),
                        fit: BoxFit.contain, // Fits the whole signature inside the box
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('Tap to browse gallery', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('Max size: 100KB (.png or .jpeg)', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],

              // Account Status (Only on Edit)
              if (_isEditMode) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Account Active Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_isActive ? 'User can log in' : 'User is disabled', style: TextStyle(color: _isActive ? AppColors.teal600 : Colors.redAccent)),
                  value: _isActive,
                  activeColor: AppColors.teal600,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ],

              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEditMode ? 'Save Changes' : 'Create User', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}