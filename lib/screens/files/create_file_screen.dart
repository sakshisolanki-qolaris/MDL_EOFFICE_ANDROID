import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class CreateFileScreen extends StatefulWidget {
  @override
  _CreateFileScreenState createState() => _CreateFileScreenState();
}

class _CreateFileScreenState extends State<CreateFileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  String _priority = 'MEDIUM'; // Match backend constants
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _submitFile() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    try {
      final apiClient = Provider.of<AuthProvider>(context, listen: false).apiClient;
      final response = await apiClient.createFile({
        'subject': _subjectController.text.trim(),
        'priority': _priority,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('e-File initiated successfully!'), backgroundColor: AppColors.green600),
        );
        // Go back to dashboard or created files
        Navigator.pushReplacementNamed(context, '/files/drafts');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? 'Failed to create file';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Subject *', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                validator: (val) => (val == null || val.length < 5) ? 'Min 5 characters required' : null,
                decoration: InputDecoration(
                  hintText: 'e.g. Budget Approval',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.teal600, width: 2)),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Low')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                  DropdownMenuItem(value: 'HIGH', child: Text('High')),
                ],
                onChanged: (val) => setState(() => _priority = val!),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFile,
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}