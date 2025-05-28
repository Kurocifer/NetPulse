import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  bool _isResending = false;

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final email = supabase.auth.currentUser?.email ?? 'your email';

    return Scaffold(
      appBar: AppBar(
        title: Text('Network Monitor', style: GoogleFonts.poppins(fontSize: 24, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email, size: 80, color: Color(0xFF1E88E5)),
            const SizedBox(height: 20),
            Text(
              'Check Your Email',
              style: GoogleFonts.poppins(fontSize: 32, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Text(
              "We've sent a verification link to $email. Please check your inbox and click the link to verify your account.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            _isResending
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      setState(() => _isResending = true);
                      try {
                        await supabase.auth.resend(
                          type: OtpType.signup, // Changed from 'signup' to OtpType.signup
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verification email resent')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to resend email: $e')),
                        );
                      } finally {
                        setState(() => _isResending = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: Text('Resend Email', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.offAllNamed('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text('Go to Login', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}