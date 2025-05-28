import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:get/get.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'auth_event.dart';
  import 'auth_state.dart';

  class AuthBloc extends Bloc<AuthEvent, NetpulseAuthState> {
    final SupabaseClient supabase = Supabase.instance.client;

    AuthBloc() : super(NetpulseAuthInitial()) {
      on<AuthSignUpRequested>(_onSignUpRequested);
      on<AuthLoginRequested>(_onLoginRequested);
      on<AuthLogoutRequested>(_onLogoutRequested);
    }

    Future<void> _onSignUpRequested(
      AuthSignUpRequested event,
      Emitter<NetpulseAuthState> emit,
    ) async {
      emit(NetpulseAuthLoading());
      try {
        final response = await supabase.auth.signUp(
          email: event.email,
          password: event.password,
        );
        if (response.user != null) {
          // Persist email and phone number
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pendingEmail', event.email);
          await prefs.setString('pendingPhoneNumber', event.phoneNumber);
          print('Signup successful: email=${event.email}, phoneNumber=${event.phoneNumber}');
          emit(NetpulseAuthSuccess());
          Get.offNamed('/confirmation'); // Redirect to ConfirmationScreen
        }
      } catch (e) {
        print('Signup error: $e');
        emit(NetpulseAuthFailure(e.toString()));
      }
    }

    Future<void> _onLoginRequested(
      AuthLoginRequested event,
      Emitter<NetpulseAuthState> emit,
    ) async {
      emit(NetpulseAuthLoading());
      try {
        await supabase.auth.signInWithPassword(
          email: event.email,
          password: event.password,
        );
        print('Login successful: email=${event.email}');
        // Retrieve pending email and phone number
        final prefs = await SharedPreferences.getInstance();
        final pendingEmail = prefs.getString('pendingEmail');
        final pendingPhoneNumber = prefs.getString('pendingPhoneNumber');
        print('Checking pending data: email=$pendingEmail, phoneNumber=$pendingPhoneNumber');
        if (pendingPhoneNumber != null && pendingEmail != null) {
          // Check if the user already has a row in the Users table
          final userData = await supabase
              .from('Users')
              .select()
              .eq('Email', pendingEmail)
              .maybeSingle();
          print('User data query result: $userData');
          if (userData == null) {
            try {
              await supabase.from('Users').insert({
                'Email': pendingEmail,
                'PhoneNumber': pendingPhoneNumber,
                'created_at': DateTime.now().toIso8601String(),
              });
              print('Inserted row into Users table: email=$pendingEmail');
              // Clear pending data
              await prefs.remove('pendingEmail');
              await prefs.remove('pendingPhoneNumber');
            } catch (e) {
              print('Insert error: $e');
            }
          } else {
            print('User already exists in Users table: $userData');
          }
        } else {
          print('No pending data to insert: email=$pendingEmail, phoneNumber=$pendingPhoneNumber');
        }
        emit(NetpulseAuthSuccess());
        Get.offAllNamed('/home');
      } catch (e) {
        print('Login error: $e');
        emit(NetpulseAuthFailure(e.toString()));
      }
    }

    Future<void> _onLogoutRequested(
      AuthLogoutRequested event,
      Emitter<NetpulseAuthState> emit,
    ) async {
      emit(NetpulseAuthLoading());
      try {
        await supabase.auth.signOut();
        emit(NetpulseAuthInitial());
        Get.offAllNamed('/login');
      } catch (e) {
        print('Logout error: $e');
        emit(NetpulseAuthFailure(e.toString()));
      }
    }
  }