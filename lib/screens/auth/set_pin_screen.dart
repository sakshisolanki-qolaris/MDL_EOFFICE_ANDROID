import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({Key? key}) : super(key: key);

  @override
  _SetPinScreenState createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePin = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final dio = Provider.of<AuthProvider>(context, listen: false).apiClient.dio;

      final response = await dio.post('/auth/set-pin', data: {
        'password': _passwordController.text,
        'newPin': _pinController.text,
      });

      if (response.statusCode == 200) {
        // Show success and pop back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Security PIN set successfully!'), backgroundColor: AppColors.green600),
        );

        // Update the AuthProvider to reflect that the PIN is now set
        Provider.of<AuthProvider>(context, listen: false).updatePinStatus(true);

        if (Navigator.canPop(context)) {
          // If they came from Create File or File Details, pop them right back to where they were!
          Navigator.pop(context);
        } else {
          // If they just logged in and had no history, send them to the Dashboard/Inbox safely
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        }
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to set PIN. Please try again.';
      if (e.response != null && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Set Security PIN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.teal600,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Icon & Instructions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ]
              ),
              child: const Icon(Icons.lock_person_rounded, size: 64, color: AppColors.teal600),
            ),
            const SizedBox(height: 24),

            const Text(
              'Create a 4-Digit PIN',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate800),
            ),
            const SizedBox(height: 8),
            const Text(
              'This PIN acts as your digital signature and will be required whenever you approve or forward an e-File.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate500, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // The Form
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                  ]
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Password Field (Verification)
                    const Text('Verify Identity', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Current Login Password',
                        prefixIcon: const Icon(Icons.password, color: AppColors.slate500),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.slate500),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password is required to set a PIN';
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // 2. New PIN Field
                    const Text('New Security PIN', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pinController,
                      obscureText: _obscurePin,
                      maxLength: 4, // Restrict exactly to 4 digits visually
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '4-Digit PIN',
                        counterText: '', // Hides the '0/4' character counter
                        prefixIcon: const Icon(Icons.dialpad, color: AppColors.slate500),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: AppColors.slate500),
                          onPressed: () => setState(() => _obscurePin = !_obscurePin),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'PIN is required';
                        if (value.length != 4) return 'PIN must be exactly 4 digits';
                        if (!RegExp(r'^\d{4}$').hasMatch(value)) return 'PIN must contain only numbers';
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _submitForm,
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : const Text('Save PIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}