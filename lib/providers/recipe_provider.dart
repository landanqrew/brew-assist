import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_config.dart';
import '../models/recipe.dart';
import '../providers/auth_provider.dart';

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

/// Fetches recipes filtered by brew method (null = all).
final recipeListProvider =
    FutureProvider.family<List<Recipe>, String?>((ref, brewMethod) async {
  var request = supabase.from('recipes').select();

  if (brewMethod != null && brewMethod.isNotEmpty) {
    request = request.eq('brew_method', brewMethod);
  }

  final data = await request
      .order('created_at', ascending: false)
      .limit(50);

  return (data as List).map((json) => Recipe.fromJson(json)).toList();
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
