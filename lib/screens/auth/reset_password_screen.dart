import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String phoneNumber;

  const ResetPasswordScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    otpController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isAuthLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify & Reset', style: TextStyle(color: AppColors.slate900, fontWeight: FontWeight.bold)),
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
                  'Verification Code',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.slate900),
                ),
                const SizedBox(height: 8),
                Text(
                  'We have sent a 6-digit code to ${widget.phoneNumber}.',
                  style: const TextStyle(fontSize: 14, color: AppColors.slate500),
                ),
                const SizedBox(height: 48),
                
                // OTP Field
                TextFormField(
                  controller: otpController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppColors.teal600),
                  decoration: InputDecoration(
                    labelText: '6-Digit OTP',
                    labelStyle: const TextStyle(fontSize: 14, color: AppColors.slate500, letterSpacing: 0),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    counterText: '',
                    filled: true,
                    fillColor: isLoading ? AppColors.slate100 : AppColors.slate50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.teal600, width: 1.5)),
                  ),
                  validator: (value) => (value == null || value.length != 6) ? 'Enter 6-digit OTP' : null,
                ),
                const SizedBox(height: 24),

                // New Password Field
                TextFormField(
                  controller: passwordController,
                  enabled: !isLoading,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.slate900),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: const TextStyle(fontSize: 14, color: AppColors.slate500),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.teal600, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.slate500, size: 20),
                      onPressed: isLoading ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: isLoading ? AppColors.slate100 : AppColors.slate50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.teal600, width: 1.5)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password is required';
                    if (value.length < 8) return 'Minimum 8 characters required';
                    // Backend regex: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9])(?!.*\s).{8,16}$/
                    bool hasUpper = value.contains(RegExp(r'[A-Z]'));
                    bool hasLower = value.contains(RegExp(r'[a-z]'));
                    bool hasDigit = value.contains(RegExp(r'[0-9]'));
                    bool hasSpecial = value.contains(RegExp(r'[^A-Za-z0-9]'));
                    if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
                      return 'Must include Uppercase, Lowercase, Number & Special Char';
                    }
                    return null;
                  },
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
                        final result = await authProvider.resetPassword(
                          widget.phoneNumber,
                          otpController.text.trim(),
                          passwordController.text.trim(),
                        );
                        if (result['success']) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
                            );
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
                        : const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Resend OTP', style: TextStyle(color: AppColors.teal600, fontWeight: FontWeight.bold)),
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
