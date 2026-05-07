import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

/// AuthState — All authentication states for AuthBloc
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before auth check
class AuthInitial extends AuthState {}

/// Loading state during async operations
class AuthLoading extends AuthState {}

/// User is authenticated and profile is loaded
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {}

/// Authentication error (login/register failed)
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Password reset email sent successfully
class ForgotPasswordSent extends AuthState {}

/// Password reset failed
class ForgotPasswordError extends AuthState {
  final String message;

  const ForgotPasswordError(this.message);

  @override
  List<Object?> get props => [message];
}
