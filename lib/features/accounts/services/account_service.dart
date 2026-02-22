import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account.dart';

class AccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all accounts (using decrypted RPC)
  Future<List<Account>> getAccounts() async {
    final response = await _supabase.rpc('get_accounts');

    // The RPC returns a json array directly
    final List<dynamic> data = response as List<dynamic>;
    return data
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Add a new account (using encrypting RPC)
  Future<Account> addAccount(Account account) async {
    final response = await _supabase.rpc(
      'add_account',
      params: {
        'p_bank_name': account.bankName,
        'p_type': account.type,
        'p_ends_with': account.endsWith,
      },
    );

    return Account.fromJson(response as Map<String, dynamic>);
  }

  // Define more basic CRUD with RPC if needed.
  // Note: update & delete operations can just be standard DB calls since we encrypt on the way in.
  // But wait, if we encrypt on the way in, updating an encrypted field requires RPC.
  // Deleting doesn't require RPC, we can just delete by ID.
  Future<void> deleteAccount(String accountId) async {
    await _supabase.from('user_personal_accounts').delete().eq('id', accountId);
  }

  // Update an account (using encrypting RPC)
  Future<Account> updateAccount(Account account) async {
    final response = await _supabase.rpc(
      'update_account',
      params: {
        'p_id': account.id,
        'p_bank_name': account.bankName,
        'p_type': account.type,
        'p_ends_with': account.endsWith,
      },
    );

    return Account.fromJson(response as Map<String, dynamic>);
  }
}
