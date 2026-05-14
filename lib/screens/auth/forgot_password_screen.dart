import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isAuthLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Forgot Password', style: TextStyle(color: AppColors.slate900, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.slate900),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reset Your Password',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.slate900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your registered phone number to receive a 6-digit verification code.',
                  style: TextStyle(fontSize: 14, color: AppColors.slate500),
                ),
                const SizedBox(height: 48),
                
                TextFormField(
                  controller: phoneController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.slate900),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(fontSize: 14, color: AppColors.slate500),
                    prefixIcon: const Icon(Icons.phone_android_outlined, color: AppColors.teal600, size: 20),
                    filled: true,
                    fillColor: isLoading ? AppColors.slate100 : AppColors.slate50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.teal600, width: 1.5)),
                    disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (value) => (value == null || value.length != 10) ? 'Enter valid 10-digit phone number' : null,
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isLoading ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        final result = await authProvider.forgotPassword(phoneController.text.trim());
                        if (result['success']) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
                            );
                            Navigator.pushNamed(context, '/auth/reset-password', arguments: phoneController.text.trim());
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message']), backgroundColor: Colors.redAccent),
                            );
                          }
                        }
                      }
                    },
                    child: isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Request OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
