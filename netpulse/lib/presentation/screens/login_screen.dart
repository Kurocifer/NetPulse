import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocListener<AuthBloc, NetpulseAuthState>(
        listener: (context, state) {
          if (state is NetpulseAuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login successful! Redirecting to Home...')),
            );
            Get.offNamed('/home'); // Redirect to HomeScreen after login
          } else if (state is NetpulseAuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLoginRequested(
                        email: 'draculemihawk232@gmail.com', // Use your valid email
                        password: 'password123',
                      ));
                },
                child: const Text('Login'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.toNamed('/create_account'); // Navigate to CreateAccountScreen
                },
                child: const Text('Go to Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}