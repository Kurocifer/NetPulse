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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pendingEmail', event.email);
        await prefs.setString('pendingPhoneNumber', event.phoneNumber);
        emit(NetpulseAuthSuccess());
        Get.offNamed('/confirmation');
      }
    } catch (e) {
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
      final prefs = await SharedPreferences.getInstance();
      final pendingEmail = prefs.getString('pendingEmail');
      final pendingPhoneNumber = prefs.getString('pendingPhoneNumber');
      if (pendingEmail != null && pendingPhoneNumber != null) {
        final userData = await supabase
            .from('Users')
            .select()
            .eq('Email', pendingEmail)
            .maybeSingle();
        if (userData == null) {
          await supabase.from('Users').insert({
            'Email': pendingEmail,
            'PhoneNumber': pendingPhoneNumber,
            'created_at': DateTime.now().toIso8601String(),
          });
          await prefs.remove('pendingEmail');
          await prefs.remove('pendingPhoneNumber');
        }
      }
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await prefs.setString('userId', userId);
        await prefs.setBool('isLoggedIn', true);
      }
      emit(NetpulseAuthSuccess());
      Get.offAllNamed('/home');
    } catch (e) {
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userId');
      emit(NetpulseAuthInitial());
      Get.offAllNamed('/login');
    } catch (e) {
      emit(NetpulseAuthFailure(e.toString()));
    }
  }
}