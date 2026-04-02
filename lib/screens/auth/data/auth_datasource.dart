import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kharcha/screens/auth/model/auth_user_model.dart';

class AuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthDataSource({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  Future<AuthUserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final String normalizedEmail = email.trim();
    final UserCredential credential;
    try {
      credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
            .collection('users')
            .doc(_emailDocId(normalizedEmail))
            .get();

        if (!snapshot.exists) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with this email.',
          );
        }
      }
      rethrow;
    }

    final User? user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Unable to complete sign-in.',
      );
    }

    await user.reload();
    final User refreshedUser = _firebaseAuth.currentUser ?? user;

    if (!refreshedUser.emailVerified) {
      try {
        await refreshedUser.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        if (e.code != 'no-current-user') {
          rethrow;
        }
      }

      await _firebaseAuth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message:
            'Email not verified. We have sent a verification email. Please verify and sign in again.',
      );
    }

    final AuthUserModel authUser = AuthUserModel.fromFirebaseUser(
      refreshedUser,
      provider: 'email',
    );
    await _upsertUser(authUser);
    return authUser;
  }

  Future<AuthUserModel> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final UserCredential credential =
        await _firebaseAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

    final User? user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Unable to create account.',
      );
    }

    final String trimmedName = fullName.trim();
    if (trimmedName.isNotEmpty) {
      try {
        await user.updateDisplayName(trimmedName);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'no-current-user') {
          rethrow;
        }
      }
    }

    if (!user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        if (e.code != 'no-current-user') {
          rethrow;
        }
      }

      await _firebaseAuth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message:
            'Account created. We have sent a verification email. Please verify and sign in.',
      );
    }

    await user.reload();

    final User refreshedUser = _firebaseAuth.currentUser ?? user;
    final AuthUserModel authUser = AuthUserModel.fromFirebaseUser(
      refreshedUser,
      provider: 'email',
      fullNameOverride: trimmedName,
    );

    await _upsertUser(authUser);
    return authUser;
  }

  Future<AuthUserModel> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-signin-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential;
    try {
      userCredential = await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          message:
              'This email already exists with email/password login. Please sign in with email to continue with the same account.',
        );
      }
      rethrow;
    }

    final User? user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Unable to complete Google sign-in.',
      );
    }

    final AuthUserModel authUser = AuthUserModel.fromFirebaseUser(
      user,
      provider: 'google',
    );
    await _upsertUser(authUser);
    return authUser;
  }

  Future<void> _upsertUser(AuthUserModel user) async {
    final String normalizedEmail = user.email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'User email is missing.',
      );
    }

    final DocumentReference<Map<String, dynamic>> userRef = _firestore
        .collection('users')
        .doc(_emailDocId(normalizedEmail));

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await userRef.get();

    final Map<String, dynamic>? existing = snapshot.data();
    final List<dynamic> existingProvidersRaw =
        (existing?['providers'] as List<dynamic>?) ?? <dynamic>[];
    final Set<String> providers = existingProvidersRaw
        .whereType<String>()
        .map((String value) => value.trim().toLowerCase())
        .where((String value) => value.isNotEmpty)
        .toSet();
    providers.add(user.provider.trim().toLowerCase());

    final String existingUid = (existing?['uid'] as String?) ?? '';
    final String selectedUid = existingUid.isNotEmpty ? existingUid : user.uid;

    final String existingFullName = (existing?['fullName'] as String?) ?? '';
    final String selectedFullName = existingFullName.isNotEmpty
        ? existingFullName
        : user.fullName;

    final String? existingPhotoUrl = existing?['photoUrl'] as String?;
    final String? selectedPhotoUrl = existingPhotoUrl ?? user.photoUrl;

    final Map<String, dynamic> data = <String, dynamic>{
      ...user.toFirestoreMap(),
      'uid': selectedUid,
      'email': normalizedEmail,
      'fullName': selectedFullName,
      'photoUrl': selectedPhotoUrl,
      'provider': user.provider,
      'providers': providers.toList()..sort(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await userRef.set(data, SetOptions(merge: true));
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> updateProfile({
    required String fullName,
  }) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found.',
      );
    }

    if (fullName.trim().isNotEmpty) {
      await user.updateDisplayName(fullName.trim());
    }

    await user.reload();

    final String normalizedEmail = user.email?.trim().toLowerCase() ?? '';
    if (normalizedEmail.isNotEmpty) {
      await _firestore.collection('users').doc(_emailDocId(normalizedEmail)).update({
        'fullName': fullName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  String _emailDocId(String email) {
    return email.trim().toLowerCase();
  }
}
