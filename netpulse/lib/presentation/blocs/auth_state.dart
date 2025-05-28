import 'package:equatable/equatable.dart';

abstract class NetpulseAuthState extends Equatable {
  const NetpulseAuthState();

  @override
  List<Object?> get props => [];
}

class NetpulseAuthInitial extends NetpulseAuthState {}

class NetpulseAuthLoading extends NetpulseAuthState {}

class NetpulseAuthSuccess extends NetpulseAuthState {}

class NetpulseAuthFailure extends NetpulseAuthState {
  final String message;

  const NetpulseAuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}