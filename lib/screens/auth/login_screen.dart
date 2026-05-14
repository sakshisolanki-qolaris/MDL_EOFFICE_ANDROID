import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. Create Controllers to read the text input
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true; // 🟢 Added state for visibility


  @override
  void dispose() {
    // Always dispose controllers to free up memory
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAuthLoading = authProvider.isAuthLoading;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background Decorative Elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal600.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal600.withOpacity(0.03),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- LOGO SECTION ---
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppColors.teal600, Color(0xFF0D9488)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'e-Office',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.slate900, letterSpacing: -0.5),
                      ),
                      const Text(
                        'MAHARASHTRA MANDAL',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.teal600, letterSpacing: 2),
                      ),
                      const SizedBox(height: 48),

                      // --- LOGIN CARD ---
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Authorized Access',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate800),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please sign in to your official account',
                                style: TextStyle(fontSize: 13, color: AppColors.slate500),
                              ),
                              const SizedBox(height: 32),

                              // Login ID Field
                              TextFormField(
                                controller: phoneController,
                                enabled: !isAuthLoading,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: AppColors.slate900),
                                decoration: InputDecoration(
                                  labelText: 'Login ID / Phone',
                                  labelStyle: const TextStyle(fontSize: 14, color: AppColors.slate500),
                                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.teal600, size: 20),
                                  filled: true,
                                  fillColor: isAuthLoading ? AppColors.slate100 : AppColors.slate50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.teal600, width: 1.5)),
                                  disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                validator: (value) => (value == null || value.length != 10) ? 'Enter valid 10-digit ID' : null,
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              TextFormField(
                                controller: passwordController,
                                enabled: !isAuthLoading,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: AppColors.slate900),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: const TextStyle(fontSize: 14, color: AppColors.slate500),
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.teal600, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.slate500, size: 20),
                                    onPressed: isAuthLoading ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: isAuthLoading ? AppColors.slate100 : AppColors.slate50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.teal600, width: 1.5)),
                                  disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                validator: (value) => (value == null || value.isEmpty) ? 'Password is required' : null,
                              ),
                              const SizedBox(height: 12),
                              
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isAuthLoading ? null : () => Navigator.pushNamed(context, '/auth/forgot-password'),
                                  child: Text('Forgot Password?', style: TextStyle(color: isAuthLoading ? AppColors.slate400 : AppColors.teal600, fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Login Button
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
                                  onPressed: isAuthLoading ? null : () async {
                                    if (_formKey.currentState!.validate()) {
                                      FocusScope.of(context).unfocus();
                                      bool success = await Provider.of<AuthProvider>(context, listen: false).login(phoneController.text.trim(), passwordController.text.trim());
                                      if (success && context.mounted) {
                                        Navigator.pushReplacementNamed(context, '/inbox');
                                      } else if (context.mounted) {
                                        final errorMsg = Provider.of<AuthProvider>(context, listen: false).authError ?? 'Invalid credentials';
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent));
                                      }
                                    }
                                  },
                                  child: isAuthLoading
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Secure Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      // --- FOOTER ---
                      Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.security_rounded, size: 14, color: AppColors.slate500),
                              SizedBox(width: 8),
                              Text('256-bit AES Encrypted Session', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Digital Workplace Solution for MM India', style: TextStyle(color: AppColors.slate500, fontSize: 10, letterSpacing: 0.5)),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}