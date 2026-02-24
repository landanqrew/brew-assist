import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_config.dart';
import '../models/recipe.dart';
import '../providers/auth_provider.dart';

// ── Composite Model ──────────────────────────────────────────────────────────

/// A recipe with its author's profile info, parsed from a Supabase join.
class RecipeFeedItem {
  const RecipeFeedItem({
    required this.recipe,
    this.authorUsername,
    this.authorDisplayName,
    this.authorAvatarUrl,
  });

  final Recipe recipe;
  final String? authorUsername;
  final String? authorDisplayName;
  final String? authorAvatarUrl;

  factory RecipeFeedItem.fromJson(Map<String, dynamic> json) {
    final p = json['profiles'] as Map<String, dynamic>?;
    return RecipeFeedItem(
      recipe: Recipe.fromJson(json),
      authorUsername: p?['username'] as String?,
      authorDisplayName: p?['display_name'] as String?,
      authorAvatarUrl: p?['avatar_url'] as String?,
    );
  }
}

// ── Read Providers ───────────────────────────────────────────────────────────

/// Fetches a single recipe by ID.
final recipeDetailProvider =
    FutureProvider.family<Recipe, String>((ref, id) async {
  final data =
      await supabase.from('recipes').select().eq('id', id).single();

  return Recipe.fromJson(data);
});

/// Fetches all recipes for the current user.
final userRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final userId = ref.read(authProvider).user?.id;
  if (userId == null) return [];

  final data = await supabase
      .from('recipes')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  return (data as List).map((json) => Recipe.fromJson(json)).toList();
});

/// Fetches recipes filtered by brew method (null = all), with author info.
final recipeListProvider =
    FutureProvider.family<List<RecipeFeedItem>, String?>((ref, brewMethod) async {
  var request = supabase.from('recipes').select('*, profiles(*)');

  if (brewMethod != null && brewMethod.isNotEmpty) {
    request = request.eq('brew_method', brewMethod);
  }

  final data = await request
      .order('created_at', ascending: false)
      .limit(50);

  return (data as List).map((j) => RecipeFeedItem.fromJson(j)).toList();
});

/// Searches recipes by title or description, with author info.
final recipeSearchProvider =
    FutureProvider.family<List<RecipeFeedItem>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final q = '%$query%';
  final data = await supabase
      .from('recipes')
      .select('*, profiles(*)')
      .or('title.ilike.$q,description.ilike.$q')
      .order('created_at', ascending: false)
      .limit(30);
  return (data as List).map((j) => RecipeFeedItem.fromJson(j)).toList();
});

/// Fetches the current user's recipes as RecipeFeedItem (with profile join).
final userRecipesFeedProvider = FutureProvider<List<RecipeFeedItem>>((ref) async {
  final userId = ref.read(authProvider).user?.id;
  if (userId == null) return [];
  final data = await supabase
      .from('recipes')
      .select('*, profiles(*)')
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  return (data as List).map((j) => RecipeFeedItem.fromJson(j)).toList();
});

/// Fetches another user's recipes as RecipeFeedItem.
final userRecipesFeedByIdProvider =
    FutureProvider.family<List<RecipeFeedItem>, String>((ref, userId) async {
  final data = await supabase
      .from('recipes')
      .select('*, profiles(*)')
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  return (data as List).map((j) => RecipeFeedItem.fromJson(j)).toList();
});

/// Fetches the current user's bookmarked/saved recipes.
final savedRecipesProvider = FutureProvider<List<RecipeFeedItem>>((ref) async {
  final me = supabase.auth.currentUser?.id;
  if (me == null) return [];
  final data = await supabase
      .from('saved_recipes')
      .select('recipes(*, profiles(*))')
      .eq('user_id', me)
      .order('created_at', ascending: false);
  return (data as List).map((row) {
    final recipeJson = row['recipes'] as Map<String, dynamic>;
    return RecipeFeedItem.fromJson(recipeJson);
  }).toList();
});

// ── Save / Bookmark Providers ────────────────────────────────────────────────

/// Whether the current user has saved the given recipe.
final isSavedByMeProvider =
    FutureProvider.family<bool, String>((ref, recipeId) async {
  final me = supabase.auth.currentUser?.id;
  if (me == null) return false;

  final data = await supabase
      .from('saved_recipes')
      .select('id')
      .eq('user_id', me)
      .eq('recipe_id', recipeId)
      .maybeSingle();

  return data != null;
});

/// Toggles save/bookmark on a recipe.
class SaveNotifier extends StateNotifier<AsyncValue<void>> {
  SaveNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> toggleSave(String recipeId) async {
    final me = supabase.auth.currentUser?.id;
    if (me == null) return;

    final currentlySaved =
        _ref.read(isSavedByMeProvider(recipeId)).valueOrNull ?? false;

    try {
      if (currentlySaved) {
        await supabase
            .from('saved_recipes')
            .delete()
            .eq('user_id', me)
            .eq('recipe_id', recipeId);
        await supabase.rpc('decrement_save_count', params: {'rid': recipeId});
      } else {
        await supabase.from('saved_recipes').insert({
          'user_id': me,
          'recipe_id': recipeId,
        });
        await supabase.rpc('increment_save_count', params: {'rid': recipeId});
      }
      _ref.invalidate(isSavedByMeProvider(recipeId));
      _ref.invalidate(recipeDetailProvider(recipeId));
      _ref.invalidate(savedRecipesProvider);
    } catch (_) {
      // Silently fail — UI stays in the previous state.
    }
  }
}

final saveNotifierProvider =
    StateNotifierProvider<SaveNotifier, AsyncValue<void>>((ref) {
  return SaveNotifier(ref);
});

// ── Submission State ─────────────────────────────────────────────────────────

enum RecipeSubmissionStatus { idle, submitting, success, error }

class RecipeSubmissionState {
  const RecipeSubmissionState({
    this.status = RecipeSubmissionStatus.idle,
    this.errorMessage,
    this.createdRecipeId,
  });

  final RecipeSubmissionStatus status;
  final String? errorMessage;
  final String? createdRecipeId;

  RecipeSubmissionState copyWith({
    RecipeSubmissionStatus? status,
    String? errorMessage,
    String? createdRecipeId,
    bool clearError = false,
  }) {
    return RecipeSubmissionState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdRecipeId: createdRecipeId ?? this.createdRecipeId,
    );
  }
}

// ── Recipe Notifier ──────────────────────────────────────────────────────────

class RecipeNotifier extends StateNotifier<RecipeSubmissionState> {
  RecipeNotifier(this._ref) : super(const RecipeSubmissionState());

  final Ref _ref;

  Future<void> createRecipe(Map<String, dynamic> fields) async {
    state = const RecipeSubmissionState(
      status: RecipeSubmissionStatus.submitting,
    );

    try {
      final userId = _ref.read(authProvider).user?.id;
      if (userId == null) {
        throw Exception('You must be signed in to create a recipe.');
      }

      fields['user_id'] = userId;

      final data = await supabase
          .from('recipes')
          .insert(fields)
          .select('id')
          .single();

      state = RecipeSubmissionState(
        status: RecipeSubmissionStatus.success,
        createdRecipeId: data['id'] as String,
      );
    } catch (e) {
      state = RecipeSubmissionState(
        status: RecipeSubmissionStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateRecipe(String id, Map<String, dynamic> fields) async {
    state = const RecipeSubmissionState(
      status: RecipeSubmissionStatus.submitting,
    );

    try {
      await supabase.from('recipes').update(fields).eq('id', id);

      state = RecipeSubmissionState(
        status: RecipeSubmissionStatus.success,
        createdRecipeId: id,
      );
    } catch (e) {
      state = RecipeSubmissionState(
        status: RecipeSubmissionStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> deleteRecipe(String id) async {
    state = const RecipeSubmissionState(
      status: RecipeSubmissionStatus.submitting,
    );

    try {
      await supabase.from('recipes').delete().eq('id', id);

      state = const RecipeSubmissionState(
        status: RecipeSubmissionStatus.success,
      );
    } catch (e) {
      state = RecipeSubmissionState(
        status: RecipeSubmissionStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  void reset() {
    state = const RecipeSubmissionState();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final recipeProvider =
    StateNotifierProvider<RecipeNotifier, RecipeSubmissionState>((ref) {
  return RecipeNotifier(ref);
});
