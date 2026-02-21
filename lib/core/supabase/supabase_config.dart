import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes the Supabase client.
///
/// Call this once in `main()` before `runApp()`.
/// Replace the placeholder values with your actual Supabase project
/// credentials (or load them from environment / build config).
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_ANON_KEY',
  );
}

/// Convenience getter for the global [SupabaseClient] instance.
SupabaseClient get supabase => Supabase.instance.client;
