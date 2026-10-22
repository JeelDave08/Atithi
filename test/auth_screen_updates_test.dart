import 'package:atithi/screens/login_screen.dart';
import 'package:atithi/screens/register_screen.dart';
import 'package:atithi/screens/terms_and_conditions_screen.dart';
import 'package:atithi/widgets/atithi_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sign-in fields fit and wrap validation errors', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    final emailField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == 'Email address',
    );
    final passwordField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == 'Password',
    );
    expect(tester.getSize(emailField).height, greaterThanOrEqualTo(56));
    expect(tester.getSize(passwordField).height, greaterThanOrEqualTo(56));
    final emailTextField = tester.widget<TextField>(emailField);
    expect(emailTextField.textAlignVertical, TextAlignVertical.center);
    expect(emailTextField.decoration?.hintMaxLines, 1);
    expect(emailTextField.decoration?.errorMaxLines, 2);
    expect(emailTextField.decoration?.isDense, isFalse);
    expect(emailTextField.decoration?.constraints?.minHeight, 56);
    expect(emailTextField.style?.fontSize, 16);
    expect(emailTextField.style?.height, 1.2);

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
    expect(tester.getSize(emailField).height, greaterThanOrEqualTo(56));
    expect(tester.getSize(passwordField).height, greaterThanOrEqualTo(56));

    expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
  });

  testWidgets('AtithiLogo uses the cream rounded-square card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: AtithiLogo())),
    );

    final logoCardFinder = find.descendant(
      of: find.byType(AtithiLogo),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                const Color(0xFFFAF5EB),
      ),
    );
    final logoCard = tester.widget<Container>(logoCardFinder);
    expect(tester.getSize(logoCardFinder).width, 128);
    expect(tester.getSize(logoCardFinder).height, 128);
    expect(
      (logoCard.decoration! as BoxDecoration).color,
      const Color(0xFFFAF5EB),
    );
  });

  testWidgets('registration phone input and country code fit and validate', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    final phoneInput = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == 'Mobile number',
    );
    await tester.ensureVisible(phoneInput);
    expect(tester.getSize(phoneInput).height, greaterThanOrEqualTo(56));
    final countryCodeBox = find.byWidgetPredicate(
      (widget) => widget is SizedBox && widget.width == 110,
    );
    expect(tester.getSize(countryCodeBox).height, greaterThanOrEqualTo(56));

    await tester.enterText(phoneInput, '123');
    await tester.pump();
    expect(find.text('Enter a valid 10-digit number.'), findsOneWidget);
    expect(tester.getSize(phoneInput).height, greaterThanOrEqualTo(56));
    expect(tester.getSize(countryCodeBox).height, greaterThanOrEqualTo(56));

    final phoneRow = find
        .ancestor(of: phoneInput, matching: find.byType(Row))
        .first;
    await tester.tap(
      find.descendant(of: phoneRow, matching: find.byType(InkWell)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search country',
      ),
      'Nepal',
    );
    expect(find.text('Nepal'), findsOneWidget);
  });

  testWidgets('unchecked terms shows the required registration snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(find.text('Please accept the Terms & Conditions'), findsOneWidget);
  });

  testWidgets('terms link opens cream terms page and I Agree closes it', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    const termsLink = 'I agree to the Terms & Conditions';
    await tester.ensureVisible(find.text(termsLink));
    await tester.tap(find.text(termsLink));
    await tester.pumpAndSettle();

    expect(find.byType(TermsAndConditionsScreen), findsOneWidget);
    for (final heading in const [
      'Acceptance',
      'Your Account',
      'Bookings & Payments',
      'Guest Conduct',
      'Privacy',
      'Cancellation & Refunds',
      'Changes to Terms',
      'Contact',
    ]) {
      expect(find.text(heading), findsOneWidget);
    }

    await tester.tap(find.text('I Agree'));
    await tester.pumpAndSettle();
    expect(find.byType(TermsAndConditionsScreen), findsNothing);
  });
}
