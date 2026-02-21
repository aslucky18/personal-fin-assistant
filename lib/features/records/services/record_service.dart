import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/record.dart';

class RecordService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get recent records
  Future<List<FinancialRecord>> getRecords({int limit = 50}) async {
    final response = await _supabase
        .from('records')
        .select()
        .order('timestamp', ascending: false)
        .limit(limit);

    return (response as List).map((e) => FinancialRecord.fromJson(e)).toList();
  }

  // Add a new record
  Future<FinancialRecord> addRecord(FinancialRecord record) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = record.toJson();
    data['user_id'] = userId;

    final response = await _supabase
        .from('records')
        .insert(data)
        .select()
        .single();

    return FinancialRecord.fromJson(response);
  }

  // Delete a record
  Future<void> deleteRecord(String recordId) async {
    await _supabase.from('records').delete().eq('id', recordId);
  }
}
