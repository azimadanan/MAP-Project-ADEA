import 'package:equatable/equatable.dart';

/// AuthEvent — All authentication events for AuthBloc
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if user is already authenticated (on app start)
class AuthCheckRequested extends AuthEvent {}

/// Login with email and password
class LoginWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginWithEmailEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Login with Google account
class LoginWithGoogleEvent extends AuthEvent {}

/// Register new account with name, email, and password
class RegisterEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const RegisterEvent({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

/// Logout current user
class LogoutEvent extends AuthEvent {}

/// Send password reset email
class ForgotPasswordEvent extends AuthEvent {
  final String email;

  const ForgotPasswordEvent({required this.email});

  @override
  List<Object?> get props => [email];
}
