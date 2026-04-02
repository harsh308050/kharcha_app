import 'package:equatable/equatable.dart';
import 'package:kharcha/screens/auth/model/auth_user_model.dart';

enum AuthActionType {
  none,
  googleSignIn,
  emailSignIn,
  emailSignUp,
  profileUpdate,
}

class AuthState extends Equatable {
  final bool isLoading;
  final bool isAuthenticated;
  final AuthActionType actionType;
  final String? errorMessage;
  final AuthUserModel? user;

  const AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    required this.actionType,
    required this.errorMessage,
    required this.user,
  });

  const AuthState.initial()
    : isLoading = false,
      isAuthenticated = false,
      actionType = AuthActionType.none,
      errorMessage = null,
      user = null;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    AuthActionType? actionType,
    String? errorMessage,
    bool clearErrorMessage = false,
    AuthUserModel? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      actionType: actionType ?? this.actionType,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isLoading,
    isAuthenticated,
    actionType,
    errorMessage,
    user,
  ];
}
