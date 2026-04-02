import 'package:firebase_auth/firebase_auth.dart';

class AuthUserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? photoUrl;
  final String provider;

  const AuthUserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.photoUrl,
    required this.provider,
  });

  factory AuthUserModel.fromFirebaseUser(
    User user, {
    required String provider,
    String? fullNameOverride,
  }) {
    return AuthUserModel(
      uid: user.uid,
      email: user.email ?? '',
      fullName: (fullNameOverride ?? user.displayName ?? '').trim(),
      photoUrl: user.photoURL,
      provider: provider,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'provider': provider,
    };
  }
}
