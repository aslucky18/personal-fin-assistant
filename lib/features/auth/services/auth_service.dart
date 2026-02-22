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
  Future<String?> uploadAvatarBytes(List<int> bytes, String extension) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = '${user.id}/$fileName';

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
}
