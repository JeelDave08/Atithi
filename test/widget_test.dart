// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atithi/main.dart';
import 'package:atithi/screens/login_screen.dart';
import 'package:atithi/screens/register_screen.dart';

void main() {
  test('transparent logo preserves original artwork and proportions', () async {
    final asset = await rootBundle.load(
      'assets/images/atithi_logo_transparent.png',
    );
    final codec = await ui.instantiateImageCodec(asset.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final pixels = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    expect(frame.image.width, 1254);
    expect(frame.image.height, 1254);
    expect(pixels!.getUint8(3), 0);

    final goldDoorPixel = (570 * frame.image.width + 620) * 4;
    expect(pixels.getUint8(goldDoorPixel + 3), 255);
    expect(pixels.getUint8(goldDoorPixel), 208);
    expect(pixels.getUint8(goldDoorPixel + 1), 163);
    expect(pixels.getUint8(goldDoorPixel + 2), 98);

    codec.dispose();
    frame.image.dispose();
  });

  testWidgets('animated branded splash transitions into existing auth flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AtithiApp());
    expect(find.byType(Image), findsOneWidget);
    final logo = tester.widget<Image>(find.byType(Image).first);
    expect(
      (logo.image as AssetImage).assetName,
      'assets/images/atithi_logo_transparent.png',
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('Better Stays. Happier Guests.'), findsOneWidget);
    expect(find.text('Every stay deserves a warm welcome.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(const Duration(milliseconds: 4300));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Explore demo (not signed in)'), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset Your Password'), findsOneWidget);
    await tester.ensureVisible(find.text('Back to Login').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to Login').last);
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);

    await tester.ensureVisible(find.text('Create Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    expect(find.text('Create Your Account'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('registration requires valid fields and terms acceptance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.ensureVisible(find.text('Create Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Account'));
    await tester.pump();
    expect(find.text('Please enter your full name.'), findsOneWidget);
    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(find.text('Please enter your mobile number.'), findsOneWidget);
    expect(find.text('Please select a country code.'), findsOneWidget);
    expect(find.text('Please create a password.'), findsOneWidget);
    expect(
      find.text('Please accept the Terms and Conditions to continue.'),
      findsOneWidget,
    );
  });

  testWidgets('registration email validation clears after correction', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'invalid-email');
    await tester.pump();
    expect(find.text('Please enter a valid email address.'), findsOneWidget);

    await tester.enterText(fields.at(1), ' guest@example.com ');
    await tester.pump();
    expect(find.text('Please enter a valid email address.'), findsNothing);
  });

  testWidgets(
    'registration checks country-specific mobile and password match',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      final fields = find.byType(TextFormField);
      await tester.tap(find.byType(DropdownButtonFormField<CountryDialCode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+91 India'));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(2), '123');
      await tester.enterText(fields.at(3), 'StaySecure8');
      await tester.enterText(fields.at(4), 'StaySecure9');
      await tester.ensureVisible(find.text('Create Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Account'));
      await tester.pump();
      expect(
        find.text('Enter a valid mobile number for India.'),
        findsOneWidget,
      );
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(
        find.byType(DropdownButtonFormField<CountryDialCode>),
        findsOneWidget,
      );

      await tester.enterText(fields.at(3), 'weakpass');
      await tester.enterText(fields.at(4), 'weakpass');
      await tester.pump();
      expect(
        find.text(
          'Include an uppercase letter, a lowercase letter, and a number.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'valid signup reports missing auth configuration without success',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      final fields = find.byType(TextFormField);
      await tester.tap(find.byType(DropdownButtonFormField<CountryDialCode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+91 India'));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(0), 'Guest Name');
      await tester.enterText(fields.at(1), 'guest@example.com');
      await tester.enterText(fields.at(2), '9876543210');
      await tester.enterText(fields.at(3), 'StaySecure8');
      await tester.enterText(fields.at(4), 'StaySecure8');

      await tester.ensureVisible(find.text('Create Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I agree to the Terms and Conditions'));
      await tester.pump();
      await tester.tap(find.text('Create Account'));
      await tester.pump();
      expect(
        find.text(
          'Authentication is not configured. Connect an auth provider before continuing.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Google button reports missing provider instead of signing in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.byType(SvgPicture), findsOneWidget);
    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    expect(
      find.text(
        'Authentication is not configured. Connect an auth provider before continuing.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('login validates email and password before authentication', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    final fields = find.byType(TextFormField);
    final emailDecoration = tester.widget<InputDecorator>(
      find.descendant(of: fields.first, matching: find.byType(InputDecorator)),
    );
    expect(emailDecoration.decoration.labelText, isNull);
    expect(emailDecoration.decoration.hintText, 'Email Address');

    await tester.ensureVisible(find.text('Sign In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);

    await tester.enterText(fields.first, 'not-an-email');
    await tester.pump();
    expect(find.text('Please enter a valid email address.'), findsOneWidget);
  });
}
