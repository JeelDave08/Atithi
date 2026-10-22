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

The Supabase URL and anon/publishable key have project defaults in
`lib/core/supabase_config.dart`, so the app can be run without extra defines.
Optional `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` Dart defines can override
those defaults. Use only the anon/publishable key; never use a secret or
service-role key in the app.

```powershell
flutter run -d <device>
```

Run the command from the directory containing `pubspec.yaml` (`D:\Atithi`).
RLS must permit published-content reads and restrict bookings to the
authenticated guest. Keep RLS enabled.
