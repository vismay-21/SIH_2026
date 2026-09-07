import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/main.dart';

void main() {
  testWidgets('customer navigation reaches the redesigned home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Bhagya'), findsOneWidget);
    expect(find.text('Fair matching for household work'), findsOneWidget);
    expect(find.text('My jobs'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(find.text('Your profile'), findsOneWidget);
  });

  testWidgets('customer registration returns to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Registration'));
    await tester.pumpAndSettle();

    expect(find.text('Customer Login'), findsOneWidget);
  });

  testWidgets('worker flow reaches all redesigned destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Registration'));
    await tester.pumpAndSettle();
    expect(find.text('Worker Login'), findsOneWidget);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Namaste, Ravi'), findsOneWidget);
    expect(find.text('New opportunities'), findsWidgets);

    for (final destination in ['Opportunities', 'My jobs', 'Profile']) {
      await tester.tap(find.text(destination));
      await tester.pump();
    }
    expect(find.text('Worker profile'), findsOneWidget);
  });

  testWidgets('worker profile navigates to verification and availability', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly Availability'), findsOneWidget);
    expect(find.text('Verification Status'), findsOneWidget);
    expect(find.text('Rookie Progression'), findsOneWidget);

    await tester.tap(find.text('Verification Status'));
    await tester.pumpAndSettle();
    expect(find.text('Full Tier-4 Verified'), findsOneWidget);
    expect(find.text('Identity & National ID'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Weekly Availability'));
    await tester.pumpAndSettle();
    expect(find.text('Recurring Weekly Schedule'), findsOneWidget);
  });

  testWidgets('worker views opportunity details and workspace', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Tap first opportunity
    await tester.tap(find.text('Kitchen sink leak repair'));
    await tester.pumpAndSettle();

    expect(find.text('Opportunity Details'), findsOneWidget);
    expect(find.text('Fixed Guaranteed Wage'), findsOneWidget);
    expect(find.text('Accept Gig'), findsOneWidget);

    // Accept opportunity
    await tester.tap(find.text('Accept Gig'));
    await tester.pumpAndSettle();

    expect(find.text('Active Job Workspace'), findsOneWidget);
    expect(find.text('Arrived & Start Work'), findsOneWidget);
  });

  testWidgets('login layout navigates to forgot password and resets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot password?'), findsOneWidget);
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot your password?'), findsOneWidget);
    expect(find.text('Send Recovery OTP'), findsOneWidget);

    // Tap Send Recovery OTP
    await tester.tap(find.text('Send Recovery OTP'));
    await tester.pumpAndSettle();

    expect(find.text('6-Digit OTP Code'), findsOneWidget);
    expect(find.text('Update Password & Sign In'), findsOneWidget);

    // Enter OTP and new password
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.enterText(find.byType(TextField).last, 'newpassword123');
    await tester.pumpAndSettle();

    // Tap Update Password & Sign In
    await tester.tap(find.text('Update Password & Sign In'));
    await tester.pumpAndSettle();

    // Successfully returns to Customer Login
    expect(find.text('Customer Login'), findsOneWidget);
  });

  testWidgets('worker profile navigates to earnings, settings, and help', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // 1. Check Earnings Navigation
    expect(find.text('Earnings & Dividends'), findsOneWidget);
    await tester.tap(find.text('Earnings & Dividends'));
    await tester.pumpAndSettle();

    expect(find.text('Earnings & Dividends'), findsWidgets);
    expect(find.text('Patronage Dividend: ₹1,240'), findsOneWidget);
    expect(find.text('0% Deductions'), findsOneWidget);
    expect(find.text('Direct Labor Wages'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // 2. Check Settings Navigation
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance & Theme'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('App Language (ಭಾಷೆ / भाषा)'), findsOneWidget);
    expect(find.text('English (English)'), findsOneWidget);
    expect(find.text('Push Notifications'), findsOneWidget);

    // Tap dark mode switch
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // 3. Check About & Help Navigation
    await tester.drag(find.byType(ListView).first, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(find.text('About & Help Support'), findsOneWidget);
    await tester.tap(find.text('About & Help Support'));
    await tester.pumpAndSettle();

    expect(find.text('Sahakaar Seva Cooperative'), findsOneWidget);
    expect(find.text('Cooperative Society Charter'), findsOneWidget);
    expect(find.text('Frequently Asked Questions (FAQ)'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Opportunities'), findsOneWidget);
  });
}
