import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            Get.offAllNamed('/home');
          } else if (state is NetpulseAuthFailure) {
            String errorMessage;
            if (state.message.toLowerCase().contains('invalid') || state.message.toLowerCase().contains('credential')) {
              errorMessage = 'Invalid email or password. Please try again.';
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
                      'Login Failed',
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
                Text('Welcome back', style: GoogleFonts.poppins(fontSize: 32, color: Colors.black87)),
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
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Forgot Password feature coming soon')),
                      );
                    },
                    child: Text('Forgot password?', style: GoogleFonts.poppins(color: Color(0xFF1E88E5))),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<AuthBloc>().add(AuthLoginRequested(
                              _emailController.text,
                              _passwordController.text,
                            ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text('Log In', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Get.to(() => const CreateAccountScreen()),
                  child: Text("Don't have an account? Sign up", style: GoogleFonts.poppins(color: Color(0xFF1E88E5))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}