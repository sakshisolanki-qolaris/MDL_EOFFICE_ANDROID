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

  @override
  void dispose() {
    // Always dispose controllers to free up memory
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the auth provider to show loading spinner on the button
    final isLoading = context.watch<AuthProvider>().isLoading;

    // 🟢 ADDED: GestureDetector to unfocus the keyboard when tapping the background
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: AppColors.navyBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo & Header
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.cyanAccent],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text('eo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('eOffice', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              Text('DIGITAL WORKPLACE SOLUTION', style: TextStyle(color: Colors.blueAccent, fontSize: 10, letterSpacing: 1)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Secure Login Title
                      Container(
                        padding: const EdgeInsets.only(left: 12),
                        decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: Colors.green, width: 4)),
                        ),
                        child: const Text('Secure Login', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 24),

                      // Phone Input
                      const Text('LOGIN ID / PHONE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: phoneController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Phone number is required';
                          if (value.length != 10) return 'Please enter a valid 10-digit number';
                          return null;
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.navyInput,
                          hintText: 'Enter 10-digit number',
                          hintStyle: const TextStyle(color: Colors.white30),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blueGrey)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('PASSWORD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Forgot Password?', style: TextStyle(color: Colors.white, fontSize: 12)),
                          )
                        ],
                      ),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Password is required';
                          return null;
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.navyInput,
                          hintText: 'Enter password',
                          hintStyle: const TextStyle(color: Colors.white30),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blueGrey)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent)),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green500,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: isLoading ? null : () async {
                            if (_formKey.currentState!.validate()) {
                              FocusScope.of(context).unfocus();

                              String phone = phoneController.text.trim();
                              String password = passwordController.text.trim();

                              bool success = await Provider.of<AuthProvider>(context, listen: false).login(phone, password);

                              if (success) {
                                if (context.mounted) {
                                  Navigator.pushReplacementNamed(context, '/inbox');
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid credentials. Please check your details.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: isLoading
                              ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                              : const Text('Access System', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}