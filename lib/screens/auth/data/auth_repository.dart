import 'package:kharcha/screens/auth/data/auth_datasource.dart';
import 'package:kharcha/screens/auth/model/auth_user_model.dart';

class AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepository({AuthDataSource? dataSource})
    : _dataSource = dataSource ?? AuthDataSource();

  Future<AuthUserModel> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _dataSource.signInWithEmail(email: email, password: password);
  }

  Future<AuthUserModel> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _dataSource.signUpWithEmail(
      fullName: fullName,
      email: email,
      password: password,
    );
  }

  Future<AuthUserModel> signInWithGoogle() {
    return _dataSource.signInWithGoogle();
  }

  Future<void> logout() {
    return _dataSource.logout();
  }

  Future<void> updateProfile({required String fullName}) {
    return _dataSource.updateProfile(fullName: fullName);
  }
}
