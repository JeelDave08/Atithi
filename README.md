# atithi

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Supabase

The app loads published properties and rooms, active services, contact details,
and bookings from Supabase. Contact form submissions are stored in
`contact_messages`.

Supabase URL and anon key are configured in `lib/core/supabase_config.dart`.
No `.env` file or Dart compile-time define is required.

```powershell
flutter run -d windows
```

Run the command from the directory containing `pubspec.yaml` (`D:\Atithi`).
The app uses the signed-in Firebase user's ID token for Supabase requests.
Configure Firebase as a Supabase third-party authentication provider, and
ensure RLS permits published-content reads and restricts bookings to the
authenticated guest. Keep RLS enabled and never use a service-role key in the
Flutter app.
