import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/goal.dart';

class GoalService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all goals for the current user
  Future<List<FinancialGoal>> getGoals() async {
    final response = await _supabase
        .from('financial_goals')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => FinancialGoal.fromJson(e)).toList();
  }

  // Add a new goal
  Future<FinancialGoal> addGoal(FinancialGoal goal) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = goal.toJson();
    data['user_id'] = userId;

    final response = await _supabase
        .from('financial_goals')
        .insert(data)
        .select()
        .single();

    return FinancialGoal.fromJson(response);
  }

  // Update a goal
  Future<FinancialGoal> updateGoal(FinancialGoal goal) async {
    final response = await _supabase
        .from('financial_goals')
        .update(goal.toJson())
        .eq('id', goal.id)
        .select()
        .single();

    return FinancialGoal.fromJson(response);
  }

  // Delete a goal
  Future<void> deleteGoal(String goalId) async {
    await _supabase.from('financial_goals').delete().eq('id', goalId);
  }
}
