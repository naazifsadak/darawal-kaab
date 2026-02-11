// Mock classes to replace Firebase dependencies
class User {
  String? displayName;
  final String email;
  final String uid;

  User({this.displayName, required this.email, required this.uid});

  Future<void> updateDisplayName(String name) async {
    displayName = name;
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

class UserCredential {
  final User? user;
  UserCredential({this.user});
}

class FirebaseAuthException implements Exception {
  final String code;
  final String message;
  FirebaseAuthException({required this.code, required this.message});

  @override
  String toString() => message;
}

class AuthService {
  // Mock singleton (optional, but consistent with typical Firebase usage)
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Mock Stream of auth changes
  Stream<User?> get authStateChanges =>
      Stream.value(null); // Always logged out for now

  // Current user
  User? get currentUser => null; // Always null for now

  // Sign Up
  Future<UserCredential?> signUp({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simulate success
    return UserCredential(
      user: User(
        email: email,
        uid: 'mock_uid_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
  }

  // Sign In
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simulate success
    return UserCredential(
      user: User(
        email: email,
        uid: 'mock_uid_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
  }

  // Sign Out
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
