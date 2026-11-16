import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Raw Firebase Auth user stream — null when signed out.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// The signed-in user's Firestore profile (role, shopId, wishlist, etc).
/// Re-fetches whenever the underlying Firebase Auth user changes.
final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) return null;
  final repo = ref.watch(authRepositoryProvider);
  return repo.fetchProfile(user.uid);
});

/// Drives the login/register/forgot-password screens: tracks in-flight
/// loading state and the last error message so the UI can render both
/// without each screen re-implementing try/catch/setState boilerplate.
class AuthController extends StateNotifier<AuthControllerState> {
  AuthController(this._repository) : super(const AuthControllerState());

  final AuthRepository _repository;

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) => _run(() => _repository.registerWithEmail(
        fullName: fullName,
        email: email,
        password: password,
      ));

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) => _run(() => _repository.loginWithEmail(email: email, password: password));

  Future<bool> loginWithGoogle() => _run(_repository.loginWithGoogle);

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _friendly(e));
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<bool> _run(Future<dynamic> Function() action) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await action();
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _friendly(e));
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'That password is too weak.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'sign-in-cancelled':
        return e.message ?? 'Sign-in was cancelled.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

class AuthControllerState {
  final bool isLoading;
  final String? errorMessage;

  const AuthControllerState({this.isLoading = false, this.errorMessage});

  AuthControllerState copyWith({bool? isLoading, String? errorMessage}) {
    return AuthControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
