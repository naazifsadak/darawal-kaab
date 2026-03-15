import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream of auth changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Current user
  User? get currentUser => _supabase.auth.currentUser;

  // Sign Up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
    );

    // Check for "fake" signup due to email enumeration protection
    if (response.user != null &&
        response.user!.identities != null &&
        response.user!.identities!.isEmpty) {
      throw const AuthException(
        'This email is already registered. Please sign in instead.',
        statusCode: '400',
      );
    }

    // If email confirmations are disabled, we get a session immediately
    if (response.session != null && response.user != null) {
      await _ensureProfile(response.user!);
    }

    return response;
  }

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Ensure profile exists upon sign in (legacy/fallback)
    if (response.user != null) {
      _ensureProfile(response.user!);
    }

    return response;
  }

  // Resend OTP
  Future<void> resendOtp(String email) async {
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Password Reset (Send OTP)
  Future<void> recoverPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Verify Email OTP
  Future<AuthResponse> verifyEmail({
    required String email,
    required String token,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );

    if (response.user != null) {
      await _ensureProfile(response.user!);
    }

    return response;
  }

  Future<void> _ensureProfile(User user) async {
    await DatabaseService().ensureProfileExists(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['display_name'],
    );
  }

  // Verify Recovery OTP
  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  // Update Password (authenticated user)
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
