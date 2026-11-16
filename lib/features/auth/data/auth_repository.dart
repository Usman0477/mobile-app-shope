import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/user_model.dart';

/// Thin wrapper around FirebaseAuth + the users/{uid} Firestore document.
/// Every screen talks to auth through this class (never directly to
/// FirebaseAuth) so mocking it in tests, or swapping providers later,
/// only touches one file.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(FirestorePaths.users).doc(uid);

  /// Registers with email/password, creates the Firestore profile, and
  /// sends the verification email. Throws [FirebaseAuthException] on
  /// failure — callers should catch it and surface `.message`.
  Future<UserModel> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(fullName);
    await user.sendEmailVerification();

    final model = UserModel(
      uid: user.uid,
      fullName: fullName,
      email: email.trim(),
      emailVerified: false,
      createdAt: DateTime.now(),
    );
    await _userDoc(user.uid).set(model.toMap());
    return model;
  }

  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _fetchOrCreateProfile(credential.user!);
  }

  Future<UserModel> loginWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    return _fetchOrCreateProfile(userCredential.user!, googleUser: googleUser);
  }

  Future<UserModel> _fetchOrCreateProfile(
    User user, {
    GoogleSignInAccount? googleUser,
  }) async {
    final doc = await _userDoc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      // Keep emailVerified in sync with the Firebase Auth record.
      if (data['emailVerified'] != user.emailVerified) {
        await _userDoc(user.uid)
            .update({'emailVerified': user.emailVerified});
      }
      return UserModel.fromMap(data, user.uid).copyWith(
        emailVerified: user.emailVerified,
      );
    }

    final model = UserModel(
      uid: user.uid,
      fullName: googleUser?.displayName ?? user.displayName ?? 'New User',
      email: user.email ?? googleUser?.email ?? '',
      photoUrl: googleUser?.photoUrl ?? user.photoURL,
      emailVerified: user.emailVerified,
      createdAt: DateTime.now(),
    );
    await _userDoc(user.uid).set(model.toMap());
    return model;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reloads the Firebase Auth user and returns the fresh
  /// `emailVerified` flag; also syncs it into Firestore.
  Future<bool> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = _auth.currentUser;
    final verified = refreshed?.emailVerified ?? false;
    if (refreshed != null) {
      await _userDoc(refreshed.uid).update({'emailVerified': verified});
    }
    return verified;
  }

  Future<UserModel?> fetchProfile(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
