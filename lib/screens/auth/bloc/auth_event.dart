import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested();
}

class AuthSignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInWithEmailRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => <Object?>[email, password];
}

class AuthSignUpWithEmailRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;

  const AuthSignUpWithEmailRequested({
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => <Object?>[fullName, email, password];
}

class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthUpdateProfileRequested extends AuthEvent {
  final String fullName;

  const AuthUpdateProfileRequested({required this.fullName});

  @override
  List<Object?> get props => <Object?>[fullName];
}
