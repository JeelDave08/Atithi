class SupabaseConfig {
  SupabaseConfig._();

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gbtojcaaxrbexhksfxuj.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdidG9qY2FheHJiZXhoa3NmeHVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI2NDQ1OTgsImV4cCI6MjEwODIyMDU5OH0.eQScOsnJfTXRLf3e8RS7z8Nag35m0gzty4LxOxChsX4',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
