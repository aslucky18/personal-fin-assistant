import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

class CategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all categories for current user
  Future<List<Category>> getCategories() async {
    final response = await _supabase
        .from('categories')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => Category.fromJson(e)).toList();
  }

  // Add a new category
  Future<Category> addCategory(Category category) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final data = category.toJson();
    data['user_id'] = userId;

    final response = await _supabase
        .from('categories')
        .insert(data)
        .select()
        .single();

    return Category.fromJson(response);
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) async {
    await _supabase.from('categories').delete().eq('id', categoryId);
  }

  /// Deletes all financial records linked to [categoryId], then deletes the category.
  Future<void> deleteCategoryWithRecords(String categoryId) async {
    await _supabase.from('records').delete().eq('category_id', categoryId);
    await _supabase.from('categories').delete().eq('id', categoryId);
  }

  // Update a category
  Future<Category> updateCategory(Category category) async {
    final response = await _supabase
        .from('categories')
        .update(category.toJson())
        .eq('id', category.id)
        .select()
        .single();

    return Category.fromJson(response);
  }
}
