import 'package:equatable/equatable.dart'; // Assuming Equatable is used

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String phoneNumber;

  const AuthSignUpRequested(this.email, this.password, this.phoneNumber);

  @override
  List<Object?> get props => [email, password, phoneNumber];
}
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();

  @override
  List<Object?> get props => [];
}