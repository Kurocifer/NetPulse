import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/network_service.dart';
import 'dart:developer' as developer;
import 'package:netpulse/main.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _ispPrefixes = ['MTN', 'ORANGE', 'CAMTEL'];

  String _determineIsp(String isp, String networkType) {
    if (networkType == 'Wi-Fi' || networkType == 'Offline') {
      return 'MTN';
    }

    for (var prefix in _ispPrefixes) {
      if (isp.startsWith(prefix)) {
        return isp.split(' ').first;
      }
    }

    return 'MTN';
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a rating.', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    if (_commentController.text.isNotEmpty && _commentController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment must be at least 10 characters if provided.', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated.');
      }

      final queryEmail = (user.email ?? '').trim();
      developer.log('Auth User Email (trimmed): "$queryEmail"');

      final response = await Supabase.instance.client
          .from('Users')
          .select('UserID')
          .ilike('Email', queryEmail)
          .limit(1);
      print('Users table query response: $response');

      if (response.isEmpty) {
        final allUsers = await Supabase.instance.client.from('Users').select('email');
        developer.log('All emails in Users table: $allUsers');
        throw Exception('User not found in Users table with email: "$queryEmail"');
      }
      final userIdFromUsersTable = response.first['UserID'] as String;

      developer.log('User ID from Users table: $userIdFromUsersTable');

      final networkService = context.read<NetworkService>();
      final loggedStates = await networkService.getLoggedNetworkStates();
      if (loggedStates.isEmpty) {
        throw Exception('No network state available.');
      }
      final latestState = loggedStates.last;
      final networkType = latestState['networkType'] as String;
      final isp = latestState['isp'] as String;

      final ispToSend = _determineIsp(isp, networkType);

      await Supabase.instance.client.from('FeedBack').insert({
        'UserID': userIdFromUsersTable,
        'Rating': _rating,
        'Comment': _commentController.text.trim(),
        'ISP': ispToSend,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for your feedback!', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );

      setState(() {
        _rating = 0;
        _commentController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting feedback: $e', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _rating = 0;
      _commentController.clear();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    LinearGradient? buttonGradient,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: buttonGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [colorScheme.background, primaryColor.withOpacity(0.7)]
                : [colorScheme.background, secondaryColor.withOpacity(0.3)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, 
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rate_review_rounded,
                        size: 50,
                        color: secondaryColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Give Your Feedback',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help us improve your network monitoring experience.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: colorScheme.onBackground.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                Text(
                  'Rate your experience:',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = starIndex;
                        });
                      },
                      child: Icon(
                        _rating >= starIndex ? Icons.star_rounded : Icons.star_border_rounded,
                        color: _rating >= starIndex ? Colors.amber[600] : colorScheme.onBackground.withOpacity(0.4),
                        size: 48,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30),

                Text(
                  'Your Comments:',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commentController,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Tell us about your experience...',
                    hintStyle: GoogleFonts.poppins(color: colorScheme.onSurface.withOpacity(0.5)),
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: secondaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16.0),
                  ),
                  style: GoogleFonts.poppins(
                    color: colorScheme.onSurface,
                  ),
                  cursorColor: secondaryColor,
                ),
                const SizedBox(height: 30),

                _buildActionButton(
                  context: context,
                  label: 'Submit Feedback',
                  icon: Icons.send_rounded,
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  buttonGradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  textColor: colorScheme.onPrimary,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _clearForm,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: secondaryColor, width: 1.5),
                    foregroundColor: secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Clear Form'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}