import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/network_service.dart';
import 'dart:developer' as developer;

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  // List of known ISP prefixes
  final List<String> _ispPrefixes = ['MTN', 'ORANGE', 'CAMTEL'];

  String _determineIsp(String isp, String networkType) {
    // For Wi-Fi or Offline, always return "MTN"
    if (networkType == 'Wi-Fi' || networkType == 'Offline') {
      return 'MTN';
    }

    // Check if ISP starts with any known prefix
    for (var prefix in _ispPrefixes) {
      if (isp.startsWith(prefix)) {
        // Trim the ISP name up to the space or end
        return isp.split(' ').first;
      }
    }

    // Fallback: return "MTN" if no match is found
    return 'MTN';
  }

  Future<void> _submitFeedback() async {
    // Validation
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating.')));
      return;
    }
    if (_commentController.text.isNotEmpty &&
        _commentController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment must be at least 10 characters if provided.'),
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

      // Log the user email for debugging
      final queryEmail = (user.email ?? '').trim();
      developer.log('Auth User Email (trimmed): "$queryEmail"');

      // Query Users table by email with case-insensitive match
      final response = await Supabase.instance.client
          .from('Users')
          .select('UserID') // Include email to verify
          .ilike('Email', queryEmail)
          .limit(1); // Limit to 1 row to avoid multiple matches
      print('Users table query response: $response');

      if (response.isEmpty) {
        // Fallback: Log all emails to debug
        final allUsers = await Supabase.instance.client
            .from('Users')
            .select('email');
        developer.log('All emails in Users table: $allUsers');
        throw Exception(
          'User not found in Users table with email: "$queryEmail"',
        );
      }
      final userIdFromUsersTable = response.first['UserID'] as String;

      developer.log('User ID from Users table: $userIdFromUsersTable');

      // Fetch the latest network state to get ISP and network type
      final networkService = context.read<NetworkService>();
      final loggedStates = await networkService.getLoggedNetworkStates();
      if (loggedStates.isEmpty) {
        throw Exception('No network state available.');
      }
      final latestState = loggedStates.last;
      final networkType = latestState['networkType'] as String;
      final isp = latestState['isp'] as String;

      // Determine the ISP to send
      final ispToSend = _determineIsp(isp, networkType);

      // Submit feedback to Supabase using the Users table id
      await Supabase.instance.client.from('FeedBack').insert({
        'UserID': userIdFromUsersTable,
        'Rating': _rating,
        'Comment': _commentController.text.trim(),
        'ISP': ispToSend,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );

      // Reset form
      setState(() {
        _rating = 0;
        _commentController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting feedback: $e')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Feedback',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Star Rating
              Text(
                'Rate your experience',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        // Set the rating directly based on starIndex
                        _rating = starIndex;
                      });
                    },
                    icon: Icon(
                      _rating >= starIndex ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    constraints: const BoxConstraints(),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Comment Field
              Text(
                'Your Feedback',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Tell us about your experience...',
                  hintStyle: GoogleFonts.poppins(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.teal),
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Submit',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearForm,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.teal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
