import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project config for EmoMulti AI Studio.
/// Project: ojclopefudlnpudvofcx (Singapore region)
class SupabaseConfig {
  static const String url = 'https://ojclopefudlnpudvofcx.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qY2xvcGVmdWRsbnB1ZHZvZmN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUwODMwMjAsImV4cCI6MjEwMDY1OTAyMH0.kcmziB6-BkBLRGDVfvc50oMcNTPVKHdYtgN51GSRsLw';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}

/// Shorthand accessor used throughout the app.
final supabase = Supabase.instance.client;
