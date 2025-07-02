import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netpulse/presentation/widgets/action_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:netpulse/main.dart';

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

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            // decoration: BoxDecoration(
            //   gradient: LinearGradient(
            //     begin: Alignment.topLeft,
            //     end: Alignment.bottomRight,
            //     colors: isDarkMode
            //         ? [colorScheme.background, primaryColor.withOpacity(0.7)]
            //         : [colorScheme.background, secondaryColor.withOpacity(0.3)],
            //   ),
            // ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 48.0 + MediaQuery.of(context).viewInsets.bottom / 2,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          'assets/images/netpulse_logo.png',
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Check Your Email',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            // color: colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "We've sent a verification link to $email. Please check your inbox and click the link to verify your account.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            // color: colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _isResending
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: secondaryColor,
                                ),
                              )
                            // : ElevatedButton(
                            //     onPressed: () async {
                            //       setState(() => _isResending = true);
                            //       try {
                            //         await supabase.auth.resend(type: OtpType.signup);
                            //         ScaffoldMessenger.of(context).showSnackBar(
                            //           SnackBar(
                            //             content: Text(
                            //               'Verification email resent',
                            //               style: GoogleFonts.poppins(
                            //                 color: Colors.white,
                            //               ),
                            //             ),
                            //             backgroundColor: secondaryColor,
                            //             behavior: SnackBarBehavior.floating,
                            //             shape: RoundedRectangleBorder(
                            //               borderRadius: BorderRadius.circular(10),
                            //             ),
                            //             margin: const EdgeInsets.all(16),
                            //           ),
                            //         );
                            //       } catch (e) {
                            //         ScaffoldMessenger.of(context).showSnackBar(
                            //           SnackBar(
                            //             content: Text(
                            //               'Failed to resend email: $e',
                            //               style: GoogleFonts.poppins(
                            //                 color: Colors.white,
                            //               ),
                            //             ),
                            //             backgroundColor: Colors.redAccent,
                            //             behavior: SnackBarBehavior.floating,
                            //             shape: RoundedRectangleBorder(
                            //               borderRadius: BorderRadius.circular(10),
                            //             ),
                            //             margin: const EdgeInsets.all(16),
                            //           ),
                            //         );
                            //       } finally {
                            //         setState(() => _isResending = false);
                            //       }
                            //     },
                            //     style: ElevatedButton.styleFrom(
                            //       minimumSize: const Size(double.infinity, 50),
                            //     ),
                            //     child: Text(
                            //       'Resend Email',
                            //       style: GoogleFonts.poppins(
                            //         fontSize: 18,
                            //         fontWeight: FontWeight.bold,
                            //       ),
                            //     ),
                            //   ),
                            : BuildActionButton(
                                context: context,
                                label: 'Resend Email',
                                onPressed: () async {
                                  setState(() => _isResending = true);
                                  try {
                                    await supabase.auth.resend(
                                      type: OtpType.signup,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Verification email resent',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: secondaryColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to resend email: $e',
                                          style: GoogleFonts.poppins(
                                            color: colorScheme.secondary,
                                          ),
                                        ),
                                        backgroundColor: colorScheme.error,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  } finally {
                                    setState(() => _isResending = false);
                                  }
                                },
                                buttonGradient: LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                textColor: colorScheme.onPrimary,
                              ),
                        const SizedBox(height: 16),
                        // ElevatedButton(
                        //   onPressed: () => Get.offAllNamed('/login'),
                        //   style: ElevatedButton.styleFrom(
                        //     minimumSize: const Size(double.infinity, 50),
                        //   ),
                        //   child: Text(
                        //     'Go to Login',
                        //     style: GoogleFonts.poppins(
                        //       fontSize: 18,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),
                        BuildActionButton(
                          context: context,
                          label: 'Go to Login',
                          onPressed: () => Get.offAllNamed('/login'),
                          buttonGradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          textColor: colorScheme.onPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildActionButton({
  //   required BuildContext context,
  //   required String label,
  //   required VoidCallback? onPressed,
  //   LinearGradient? buttonGradient,
  //   required Color textColor,
  // }) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       gradient: buttonGradient,
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: ElevatedButton(
  //       onPressed: onPressed,
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: Colors.transparent,
  //         foregroundColor: textColor,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         padding: EdgeInsets.zero,
  //         elevation: 0,
  //         shadowColor: Colors.transparent,
  //       ),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             const SizedBox(width: 8),
  //             Expanded(
  //               child: Text(
  //                 label,
  //                 textAlign: TextAlign.center,
  //                 overflow: TextOverflow.ellipsis,
  //                 maxLines: 1,
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
