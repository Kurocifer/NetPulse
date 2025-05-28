import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network Monitor', style: GoogleFonts.poppins(fontSize: 24, color: Colors.white)),
      ),
      body: BlocListener<AuthBloc, NetpulseAuthState>(
        listener: (context, state) {
          if (state is NetpulseAuthSuccess) {
            Get.offNamed('/confirmation');
          } else if (state is NetpulseAuthFailure) {
            String errorMessage;
            if (state.message.toLowerCase().contains('invalid') || state.message.toLowerCase().contains('email') || state.message.toLowerCase().contains('exists')) {
              errorMessage = 'This email is already in use or invalid. Please try a different email.';
            } else if (state.message.toLowerCase().contains('network') || state.message.toLowerCase().contains('connection')) {
              errorMessage = 'Unable to connect. Please check your internet connection and try again.';
            } else if (state.message.toLowerCase().contains('timeout')) {
              errorMessage = 'Connection timed out. Please try again later.';
            } else {
              errorMessage = 'An unexpected error occurred. Please try again later.';
            }
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Center( // Centered title
                    child: Text(
                      'Account Creation Failed',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  content: Text(
                    errorMessage,
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  backgroundColor: Colors.white,
                  elevation: 8,
                );
              },
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Create your account', style: GoogleFonts.poppins(fontSize: 32, color: Colors.black87)),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email, color: Color(0xFF1E88E5)),
                    border: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone number (optional)',
                    prefixIcon: const Icon(Icons.phone, color: Color(0xFF1E88E5)),
                    border: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  validator: (value) {
                    if (value != null && (!value.startsWith('+') || value.length < 10)) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF1E88E5)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Color(0xFF1E88E5)),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF1E88E5)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off, color: Color(0xFF1E88E5)),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<AuthBloc>().add(AuthSignUpRequested(
                              _emailController.text,
                              _passwordController.text,
                              _phoneController.text,
                            ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text('Create Account', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('Back to Login', style: GoogleFonts.poppins(color: Color(0xFF1E88E5))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}