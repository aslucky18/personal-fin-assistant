import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/liability.dart';

class LiabilityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all liabilities for the current user
  Future<List<Liability>> getLiabilities() async {
    final response = await _supabase
        .from('liabilities')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => Liability.fromJson(e)).toList();
  }

  // Add a new liability
  Future<Liability> addLiability(Liability liability) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = liability.toJson();
    data['user_id'] = userId;

    final response = await _supabase
        .from('liabilities')
        .insert(data)
        .select()
        .single();

    return Liability.fromJson(response);
  }

  // Update a liability
  Future<Liability> updateLiability(Liability liability) async {
    final response = await _supabase
        .from('liabilities')
        .update(liability.toJson())
        .eq('id', liability.id)
        .select()
        .single();

    return Liability.fromJson(response);
  }

  // Delete a liability
  Future<void> deleteLiability(String liabilityId) async {
    await _supabase.from('liabilities').delete().eq('id', liabilityId);
  }
}
