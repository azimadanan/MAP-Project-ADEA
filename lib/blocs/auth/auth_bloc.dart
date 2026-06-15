import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../repositories/user_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Internal event — fired when Firebase auth state changes
class _AuthStateChanged extends AuthEvent {
  final dynamic firebaseUser;
  const _AuthStateChanged(this.firebaseUser);
  @override
  List<Object?> get props => [firebaseUser];
}

/// AuthBloc — Manages all authentication state
/// Listens to Firebase Auth stream and handles login/register/logout/reset
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final UserRepository _userRepository;
  StreamSubscription<User?>? _authSubscription;

  AuthBloc({
    required AuthService authService,
    required UserRepository userRepository,
  })  : _authService = authService,
        _userRepository = userRepository,
        super(AuthInitial()) {
    // Register event handlers
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginWithEmailEvent>(_onLoginWithEmail);
    on<LoginWithGoogleEvent>(_onLoginWithGoogle);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<_AuthStateChanged>(_onAuthStateChanged);

    // Listen to Firebase Auth stream
    _authSubscription = _authService.authStateChanges.listen(
      (user) => add(_AuthStateChanged(user)),
    );
  }

  Future<UserModel> _updateStreakIfNecessary(UserModel userModel) async {
    final now = DateTime.now();
    final prefs = Map<String, dynamic>.from(userModel.preferences);
    final lastActiveStr = prefs['lastActiveDate'] as String?;
    int currentStreak = prefs['streak'] as int? ?? 1;

    final todayStr = "${now.year}-${now.month}-${now.day}";
    if (lastActiveStr != todayStr) {
      if (lastActiveStr != null) {
        final lastActiveParts = lastActiveStr.split('-');
        if (lastActiveParts.length == 3) {
          final lastActiveDate = DateTime(
            int.parse(lastActiveParts[0]),
            int.parse(lastActiveParts[1]),
            int.parse(lastActiveParts[2]),
          );
          final todayDate = DateTime(now.year, now.month, now.day);
          final difference = todayDate.difference(lastActiveDate).inDays;
          if (difference == 1) {
            currentStreak += 1;
          } else if (difference > 1) {
            currentStreak = 1;
          }
        }
      } else {
        currentStreak = 1;
      }
      prefs['lastActiveDate'] = todayStr;
      prefs['streak'] = currentStreak;

      try {
        await _userRepository.updateUser(userModel.uid, {'preferences': prefs});
        return userModel.copyWith(preferences: prefs);
      } catch (_) {
        return userModel;
      }
    }
    return userModel;
  }

  /// Handle auth check on app startup
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final userModel = await _userRepository.getUser(user.uid);
        if (userModel != null) {
          final updatedUser = await _updateStreakIfNecessary(userModel);
          emit(AuthAuthenticated(updatedUser));
        } else {
          // User exists in Auth but not in Firestore — create profile
          final todayStr = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
          final newUser = UserModel(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            createdAt: user.metadata.creationTime ?? DateTime.now(),
            avatar: user.photoURL,
            preferences: {
              'streak': 1,
              'lastActiveDate': todayStr,
            },
          );
          await _userRepository.createUser(newUser);
          emit(AuthAuthenticated(newUser));
        }
      } catch (e) {
        emit(AuthAuthenticated(UserModel(
          uid: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          createdAt: user.metadata.creationTime ?? DateTime.now(),
          avatar: user.photoURL,
          preferences: const {},
        )));
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  /// Internal handler for Firebase auth state changes
  Future<void> _onAuthStateChanged(
    _AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.firebaseUser as User?;
    if (user != null) {
      try {
        final userModel = await _userRepository.getUser(user.uid);
        if (userModel != null) {
          final updatedUser = await _updateStreakIfNecessary(userModel);
          emit(AuthAuthenticated(updatedUser));
        } else {
          // Fallback: create from Firebase user data
          emit(AuthAuthenticated(UserModel(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            createdAt: user.metadata.creationTime ?? DateTime.now(),
            avatar: user.photoURL,
            preferences: const {},
          )));
        }
      } catch (e) {
        emit(AuthAuthenticated(UserModel(
          uid: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          createdAt: user.metadata.creationTime ?? DateTime.now(),
          avatar: user.photoURL,
          preferences: const {},
        )));
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  /// Handle email/password login
  Future<void> _onLoginWithEmail(
    LoginWithEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.signInWithEmail(event.email, event.password);
      // Auth stream will emit AuthAuthenticated
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Handle Google Sign-In
  Future<void> _onLoginWithGoogle(
    LoginWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await _authService.signInWithGoogle();
      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        // Create or fetch user profile in Firestore
        final userModel = await _userRepository.createOrUpdateGoogleUser(firebaseUser);
        // Emit directly — don't wait for the auth stream to avoid race condition
        emit(AuthAuthenticated(userModel));
      } else {
        emit(const AuthError('Google Sign-In failed: no user returned'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Google Sign-In failed'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Handle new account registration
  Future<void> _onRegister(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await _authService.registerWithEmail(
        event.email,
        event.password,
        event.name,
      );

      final user = credential.user;
      if (user != null) {
        // Save user profile to Firestore
        final todayStr = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
        final userModel = UserModel(
          uid: user.uid,
          name: event.name.trim(),
          email: event.email.trim(),
          createdAt: DateTime.now(),
          avatar: null,
          preferences: {
            'streak': 1,
            'lastActiveDate': todayStr,
          },
        );
        await _userRepository.createUser(userModel);
        emit(AuthAuthenticated(userModel));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Handle logout
  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Handle forgot password
  Future<void> _onForgotPassword(
    ForgotPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authService.resetPassword(event.email);
      emit(ForgotPasswordSent());
    } catch (e) {
      emit(ForgotPasswordError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
