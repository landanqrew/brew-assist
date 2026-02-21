import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Initializes the Supabase client.
///
/// Reads credentials from compile-time environment variables.
/// Run with: `flutter run --dart-define-from-file=.env.json`
Future<void> initSupabase() async {
  assert(
    _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty,
    'Supabase credentials missing. '
    'Run with: flutter run --dart-define-from-file=.env.json',
  );
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );
}

/// Convenience getter for the global [SupabaseClient] instance.
SupabaseClient get supabase => Supabase.instance.client;
