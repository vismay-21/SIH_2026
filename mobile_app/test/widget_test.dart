import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/main.dart';
import 'package:mobile_app/services/api_client.dart';

void main() {
  setUp(() {
    ApiClient.mockHandler = (RequestOptions options) async {
      final path = options.path;

      if (path.contains('/auth/demo-users')) {
        return Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 'success',
            'data': [
              {
                'id': 'demo-customer-1',
                'email': 'customer1@example.com',
                'role': 'customer',
                'full_name': 'Bhagya Patel',
                'is_active': true,
              },
              {
                'id': 'demo-worker-1',
                'email': 'worker1@example.com',
                'role': 'worker',
                'full_name': 'Ravi Kumar',
                'is_active': true,
              },
            ],
          },
        );
      }

      if (path.contains('/auth/login')) {
        final data = options.data as Map<String, dynamic>?;
        final role = (data?['role'] as String?)?.toLowerCase() ?? 'customer';
        final name = role == 'customer' ? 'Bhagya' : 'Ravi';
        return Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 'success',
            'data': {
              'token': 'mock-access-token-123',
              'token_type': 'bearer',
              'user': {
                'id': 'user-123',
                'email': data?['email'] ?? 'test@example.com',
                'role': role,
                'full_name': name,
                'phone_number': '+919876543210',
                'is_active': true,
              },
            },
          },
        );
      }

      if (path.contains('/worker/opportunities')) {
        return Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 'success',
            'data': {
              'items': [
                {
                  'id': 'opp-sink-repair',
                  'gig_id': 'gig-123',
                  'worker_id': 'worker-1',
                  'status': 'OFFERED',
                  'base_price': 600.0,
                  'base_price_snapshot': 600.0,
                  'final_score_snapshot': 0.95,
                  'premium_percentage': 0.08,
                  'exact_wage': 650.0,
                  'offered_at': '2026-09-10T10:00:00Z',
                  'gig': {
                    'id': 'gig-123',
                    'category_id': 'cat-plumbing',
                    'category_name': 'Plumbing',
                    'gig_type': 'STANDARD',
                    'description': 'Kitchen sink pipe leaking under sink',
                    'instructions': 'Please bring pipe wrench',
                    'address': 'Indiranagar, Bangalore',
                    'scheduled_date': 'Today',
                    'scheduled_start_time': '4:00 PM',
                    'expected_duration_minutes': 120,
                    'material_procurement_mode': 'CUSTOMER_PURCHASES',
                    'tasks': [
                      {
                        'id': 'item-1',
                        'task_id': 'task-1',
                        'task_name': 'Kitchen sink leak repair',
                        'quantity': 1,
                        'base_rate': 600.0,
                        'estimated_duration_minutes': 120,
                      },
                    ],
                  },
                },
              ],
              'total': 1,
              'page': 1,
              'page_size': 20,
              'pages': 1,
            },
          },
        );
      }

      if (path.contains('/customer/gigs') || path.contains('/worker/gigs')) {
        return Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 'success',
            'data': {
              'items': [],
              'total': 0,
              'page': 1,
              'page_size': 20,
              'pages': 0,
            },
          },
        );
      }

      return null;
    };
  });

  tearDown(() {
    ApiClient.mockHandler = null;
  });

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
