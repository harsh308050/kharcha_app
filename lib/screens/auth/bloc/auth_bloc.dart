import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kharcha/screens/auth/bloc/auth_event.dart';
import 'package:kharcha/screens/auth/bloc/auth_state.dart';
import 'package:kharcha/screens/auth/data/auth_repository.dart';
import 'package:kharcha/screens/auth/model/auth_user_model.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({AuthRepository? repository})
    : _repository = repository ?? AuthRepository(),
      super(const AuthState.initial()) {
    on<AuthSignInWithGoogleRequested>(_onGoogleSignInRequested);
    on<AuthSignInWithEmailRequested>(_onEmailSignInRequested);
    on<AuthSignUpWithEmailRequested>(_onEmailSignUpRequested);
    on<AuthErrorCleared>(_onAuthErrorCleared);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUpdateProfileRequested>(_onUpdateProfileRequested);
  }

  Future<void> _onGoogleSignInRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        actionType: AuthActionType.googleSignIn,
        clearErrorMessage: true,
      ),
    );

    try {
      final AuthUserModel user = await _repository.signInWithGoogle();
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          actionType: AuthActionType.none,
          user: user,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          actionType: AuthActionType.none,
          errorMessage: _mapAuthError(e),
        ),
      );
    }
  }

  Future<void> _onEmailSignInRequested(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        actionType: AuthActionType.emailSignIn,
        clearErrorMessage: true,
      ),
    );

    try {
      final AuthUserModel user = await _repository.signInWithEmail(
        email: event.email.trim(),
        password: event.password,
      );
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          actionType: AuthActionType.none,
          user: user,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          actionType: AuthActionType.none,
          errorMessage: _mapAuthError(e),
        ),
      );
    }
  }

  Future<void> _onEmailSignUpRequested(
    AuthSignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        actionType: AuthActionType.emailSignUp,
        clearErrorMessage: true,
      ),
    );

    try {
      final AuthUserModel user = await _repository.signUpWithEmail(
        fullName: event.fullName.trim(),
        email: event.email.trim(),
        password: event.password,
      );

      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          actionType: AuthActionType.none,
          user: user,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          actionType: AuthActionType.none,
          errorMessage: _mapAuthError(e),
        ),
      );
    }
  }

  void _onAuthErrorCleared(AuthErrorCleared event, Emitter<AuthState> emit) {
    emit(state.copyWith(clearErrorMessage: true));
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        actionType: AuthActionType.none,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.logout();
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          actionType: AuthActionType.none,
          user: null,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          actionType: AuthActionType.none,
          errorMessage: _mapAuthError(e),
        ),
      );
    }
  }

  Future<void> _onUpdateProfileRequested(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        actionType: AuthActionType.profileUpdate,
        clearErrorMessage: true,
      ),
    );

    try {
      await _repository.updateProfile(fullName: event.fullName);
      emit(
        state.copyWith(
          isLoading: false,
          actionType: AuthActionType.none,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          actionType: AuthActionType.none,
          errorMessage: _mapAuthError(e),
        ),
      );
    }
  }

  String _mapAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
        case 'google-signin-cancelled':
          return 'Google sign-in was cancelled.';
        case 'email-not-verified':
          return 'Email is not verified. We sent a verification email. Please verify and sign in again.';
        case 'account-exists-with-different-credential':
          return 'This email already exists with email/password login. Sign in with email to continue using the same account.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }

    return 'Something went wrong. Please try again.';
  }
}
