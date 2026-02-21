import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_config.dart';
import '../providers/auth_provider.dart';

// ── Check-in Submission State ────────────────────────────────────────────────

/// Represents the state of a check-in submission.
enum CheckInSubmissionStatus { idle, submitting, success, error }

class CheckInSubmissionState {
  const CheckInSubmissionState({
    this.status = CheckInSubmissionStatus.idle,
    this.errorMessage,
  });

  final CheckInSubmissionStatus status;
  final String? errorMessage;

  CheckInSubmissionState copyWith({
    CheckInSubmissionStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CheckInSubmissionState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── Check-in Notifier ────────────────────────────────────────────────────────

/// A [StateNotifier] that handles submitting check-ins to Supabase and
/// updating the coffee's aggregate rating data client-side.
class CheckInNotifier extends StateNotifier<CheckInSubmissionState> {
  CheckInNotifier(this._ref) : super(const CheckInSubmissionState());

  final Ref _ref;

  /// Submits a new check-in to the `check_ins` table and updates the
  /// coffee's `avg_rating` and `check_in_count` fields.
  ///
  /// Throws on failure and sets the error state.
  Future<void> submitCheckIn({
    required String coffeeId,
    required double rating,
    String? notes,
    List<String>? flavorTags,
    String? preparation,
    String? specialtyDrink,
    String? venueType,
    String? venueId,
    String? photoUrl,
  }) async {
    state = const CheckInSubmissionState(
      status: CheckInSubmissionStatus.submitting,
    );

    try {
      final userId = _ref.read(authProvider).user?.id;
      if (userId == null) {
        throw Exception('You must be signed in to check in a coffee.');
      }

      // Insert the check-in row.
      // `preparation` maps to the existing `brew_method` column.
      await supabase.from('check_ins').insert({
        'user_id': userId,
        'coffee_id': coffeeId,
        'rating': rating,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (flavorTags != null && flavorTags.isNotEmpty)
          'flavor_tags': flavorTags,
        if (preparation != null) 'brew_method': preparation,
        if (specialtyDrink != null && specialtyDrink.trim().isNotEmpty)
          'specialty_drink': specialtyDrink.trim(),
        if (venueType != null) 'venue_type': venueType,
        if (venueId != null) 'venue_id': venueId,
        if (photoUrl != null) 'photo_url': photoUrl,
      });

      // Update the coffee's avg_rating and check_in_count client-side.
      await _updateCoffeeAggregates(coffeeId, rating);

      state = const CheckInSubmissionState(
        status: CheckInSubmissionStatus.success,
      );
    } catch (e) {
      state = CheckInSubmissionState(
        status: CheckInSubmissionStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Fetches the coffee's current aggregate values, computes the new average,
  /// and writes them back. This is a simple client-side approach suitable for
  /// MVP; a Supabase RPC/trigger would be more robust at scale.
  Future<void> _updateCoffeeAggregates(
    String coffeeId,
    double newRating,
  ) async {
    try {
      final data = await supabase
          .from('coffees')
          .select('avg_rating, check_in_count')
          .eq('id', coffeeId)
          .single();

      final currentAvg = (data['avg_rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount = (data['check_in_count'] as num?)?.toInt() ?? 0;

      final newCount = currentCount + 1;
      final newAvg = ((currentAvg * currentCount) + newRating) / newCount;

      await supabase.from('coffees').update({
        'avg_rating': double.parse(newAvg.toStringAsFixed(2)),
        'check_in_count': newCount,
      }).eq('id', coffeeId);
    } catch (_) {
      // Non-critical — the check-in was already saved. Aggregate updates
      // failing shouldn't block the user experience.
    }
  }

  /// Resets the submission state back to idle.
  void reset() {
    state = const CheckInSubmissionState();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// Provider for check-in submission state and operations.
final checkInProvider =
    StateNotifierProvider<CheckInNotifier, CheckInSubmissionState>((ref) {
  return CheckInNotifier(ref);
});
