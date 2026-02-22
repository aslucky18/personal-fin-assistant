import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserProfile.fromJson(response);
  }

  // Update profile
  Future<UserProfile> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? gender,
    DateTime? dateOfBirth,
    double? professionalSalary,
    int? salaryCreditDate,
    double? fixedAllowances,
    String? jobTitle,
    String? companyName,
    String? professionType,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (gender != null) updates['gender'] = gender;
    if (dateOfBirth != null) {
      updates['date_of_birth'] = dateOfBirth.toIso8601String();
    }
    if (professionalSalary != null) {
      updates['professional_salary'] = professionalSalary;
    }
    if (salaryCreditDate != null) {
      updates['salary_credit_date'] = salaryCreditDate;
    }
    if (fixedAllowances != null) {
      updates['fixed_allowances'] = fixedAllowances;
    }
    if (jobTitle != null) updates['job_title'] = jobTitle;
    if (companyName != null) updates['company_name'] = companyName;
    if (professionType != null) updates['profession_type'] = professionType;

    final response = await _supabase
        .from('user_profiles')
        .update(updates)
        .eq('id', user.id)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  // Upload Avatar
  Future<String?> uploadProfilePicture(List<int> bytes, String userId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';

    await _supabase.storage
        .from('avatars')
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(upsert: true),
        );

    return _supabase.storage.from('avatars').getPublicUrl(path);
  }

  // Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  // Send a temporary password to the user's email via Edge Function
  Future<void> sendPasswordReset({required String email}) async {
    final res = await _supabase.functions.invoke(
      'send-temp-password',
      body: {'email': email},
    );
    if (res.data?['error'] != null) {
      throw Exception(res.data['error']);
    }
  }

  // Change the current user's password and clear the temp password flags
  Future<void> changePassword({required String newPassword}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    // Clear all temp-password and must-change flags
    await _supabase
        .from('user_profiles')
        .update({
          'must_change_password': false,
          'temp_pwd_expires_at': null,
          'failed_login_attempts': 0,
          'account_locked_until': null,
        })
        .eq('id', user.id);
  }

  // Called after a failed login — increments counter, locks after 5 failures.
  // Uses anon-accessible SECURITY DEFINER function (no session required).
  Future<Map<String, dynamic>> recordFailedLogin(String email) async {
    final result = await _supabase.rpc(
      'record_failed_login',
      params: {'p_email': email},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  // Called after a successful login — resets the failed-attempt counter.
  Future<void> recordSuccessfulLogin() async {
    await _supabase.rpc('record_successful_login');
  }

  // Delete the user's account and all associated data.
  // Uses a SECURITY DEFINER Postgres function so no admin/service-role key is needed.
  Future<void> deleteUserAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Calls the `delete_user()` SQL function which deletes profile data
    // then removes the auth.users row — all within the user's own session.
    await _supabase.rpc('delete_user');

    // Sign out locally after server-side deletion
    await _supabase.auth.signOut();
  }
}
