/// 🔐 Supabase Configuration
///
/// Store your Supabase credentials here.
///
/// ⚠️ IMPORTANT SECURITY NOTES:
/// 1. Never commit real credentials to Git
/// 2. Use environment variables in production
/// 3. Add this file to .gitignore
/// 4. Create a .env file for real projects
class SupabaseConfig {
  // 🚀 Get these from: https://supabase.com/dashboard/project/_/settings/api

  /// Your Supabase project URL
  /// Format: https://xxxxxxxxxxxxx.supabase.co
  static const String supabaseUrl = 'https://mnwnustvtvfgxtxdmteo.supabase.co';

  /// Your Supabase anonymous/public key
  /// This is safe to expose in client-side code
  /// Format: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ud251c3R2dHZmZ3h0eGRtdGVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4NDA5OTksImV4cCI6MjA4MzQxNjk5OX0.lbkR-_ASwSwfktfcybMh34cp4qCtFN-ezk6Hac_gT7A';

  // Private constructor to prevent instantiation
  SupabaseConfig._();
}

/// 📝 HOW TO GET YOUR CREDENTIALS:
/// 
/// 1. Go to https://supabase.com/dashboard
/// 2. Select your project (or create one)
/// 3. Click on Settings (gear icon) in the left sidebar
/// 4. Click on "API" 
/// 5. Copy:
///    - Project URL → paste in supabaseUrl
///    - anon public key → paste in supabaseAnonKey
/// 
/// 🔒 SECURITY BEST PRACTICES:
/// 
/// For production apps, use flutter_dotenv:
/// 
/// 1. Add to pubspec.yaml:
///    dependencies:
///      flutter_dotenv: ^5.1.0
/// 
/// 2. Create .env file:
///    SUPABASE_URL=your_url_here
///    SUPABASE_ANON_KEY=your_key_here
/// 
/// 3. Add .env to .gitignore
/// 
/// 4. Load in main.dart:
///    await dotenv.load(fileName: ".env");
///    final url = dotenv.env['SUPABASE_URL']!;
///    final key = dotenv.env['SUPABASE_ANON_KEY']!;