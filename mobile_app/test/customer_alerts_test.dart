import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_app/models/api/api_models.dart';
import 'package:mobile_app/models/customer_gig_workflow.dart';
import 'package:mobile_app/providers/customer_gigs_provider.dart';
import 'package:mobile_app/providers/customer_notifications_provider.dart';
import 'package:mobile_app/screens/customer/alerts/customer_navigation_3_screen.dart';
import 'package:mobile_app/screens/customer/my_jobs/customer_navigation_2_screen.dart';

void main() {
  group('Customer Alerts & Worker Acceptance Notification Tests', () {
    testWidgets('Renders worker accepted card when candidate accepts a gig',
        (tester) async {
      const candidate = GigCandidate(
        workerId: 'worker-123',
        name: 'Rajesh Sharma',
        initials: 'RS',
        skill: 'Plumbing Specialist',
        wage: '₹650',
        rating: '4.8',
        experience: '5 yrs',
        jobs: '58 jobs',
        summary: 'Expert plumber',
        factors: ['Top Rated'],
      );

      final gig = CustomerGig(
        id: 'gig-abc',
        title: 'Water Pipe Leak Repair',
        category: 'Plumbing',
        description: 'Fix bathroom pipe',
        when: 'Today at 2:00 PM',
        location: 'Gandhinagar',
        duration: '60 mins',
        stage: GigStage.seeking,
        materials: 'Customer provides',
        instructions: 'Call on arrival',
        candidates: [candidate],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerGigsProvider.overrideWith(
              () => _MockCustomerGigsNotifier([gig]),
            ),
            customerNotificationsProvider.overrideWith(
              () => _MockCustomerNotificationsNotifier(const []),
            ),
          ],
          child: const MaterialApp(
            home: CustomerNavigation3Screen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the prominent worker accepted card appears
      expect(find.text('Rajesh Sharma accepted your gig'), findsOneWidget);
      expect(find.text('ACCEPTED'), findsOneWidget);
      expect(
        find.textContaining('Water Pipe Leak Repair'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Wage offer: ₹650'),
        findsOneWidget,
      );
    });

    testWidgets('Renders backend notification when WORKER_ACCEPTED event occurs',
        (tester) async {
      final notif = NotificationDto(
        id: 'notif-1',
        recipientId: 'cust-1',
        gigId: 'gig-abc',
        type: 'WORKER_ACCEPTED',
        title: 'Vikram Patel accepted your gig',
        body: 'Vikram Patel has accepted the opportunity for your gig "Drainage pipe cleaning".',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerGigsProvider.overrideWith(
              () => _MockCustomerGigsNotifier(const []),
            ),
            customerNotificationsProvider.overrideWith(
              () => _MockCustomerNotificationsNotifier([notif]),
            ),
          ],
          child: const MaterialApp(
            home: CustomerNavigation3Screen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Vikram Patel accepted your gig'), findsOneWidget);
      expect(
        find.textContaining('accepted the opportunity for your gig'),
        findsOneWidget,
      );
      expect(find.text('1 new'), findsOneWidget);
    });

    testWidgets('CustomerNavigation2Screen renders merged ACTIVE/UPCOMING tab and shows active gigs',
        (tester) async {
      const gigActive = CustomerGig(
        id: 'gig-1',
        title: 'Active Pipe Repair',
        category: 'Plumbing',
        description: 'Fixing pipe now',
        when: 'Today at 2:00 PM',
        location: 'Gandhinagar',
        duration: '60 mins',
        stage: GigStage.active,
        materials: 'Customer provides',
        instructions: 'Call on arrival',
        candidates: [],
      );

      const gigScheduled = CustomerGig(
        id: 'gig-2',
        title: 'Scheduled Electrical Inspection',
        category: 'Electrical',
        description: 'Checking wiring tomorrow',
        when: 'Tomorrow at 10:00 AM',
        location: 'Gandhinagar',
        duration: '45 mins',
        stage: GigStage.scheduled,
        materials: 'Customer provides',
        instructions: 'Ring bell',
        candidates: [],
      );

      const gigCompleted = CustomerGig(
        id: 'gig-3',
        title: 'Past Carpentry Fix',
        category: 'Carpentry',
        description: 'Fixed door lock',
        when: 'Yesterday',
        location: 'Gandhinagar',
        duration: '30 mins',
        stage: GigStage.completed,
        materials: 'Customer provides',
        instructions: 'Done',
        candidates: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerGigsProvider.overrideWith(
              () => _MockCustomerGigsNotifier(
                [gigActive, gigScheduled],
                completedGigs: [gigCompleted],
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CustomerNavigation2Screen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the merged ACTIVE/UPCOMING tab exists and displays count (2)
      expect(find.text('ACTIVE/UPCOMING (2)'), findsOneWidget);
      expect(find.text('Completed (1)'), findsOneWidget);

      // Verify both active and scheduled gigs appear in the unified ACTIVE/UPCOMING tab
      expect(find.text('Active Pipe Repair'), findsOneWidget);
      expect(find.text('Scheduled Electrical Inspection'), findsOneWidget);
    });
  });
}

class _MockCustomerGigsNotifier extends CustomerGigsNotifier {
  final List<CustomerGig> mockGigs;
  final List<CustomerGig> mockCompleted;
  _MockCustomerGigsNotifier(this.mockGigs, {List<CustomerGig>? completedGigs})
      : mockCompleted = completedGigs ?? const [];

  @override
  CustomerGigsState build() {
    return CustomerGigsState(
      activeGigs: mockGigs,
      completedGigs: mockCompleted,
      isLoading: false,
    );
  }

  @override
  Future<void> loadGigs({bool silent = false}) async {}
}

class _MockCustomerNotificationsNotifier
    extends CustomerNotificationsNotifier {
  final List<NotificationDto> mockNotifs;
  _MockCustomerNotificationsNotifier(this.mockNotifs);

  @override
  CustomerNotificationsState build() {
    final unread = mockNotifs.where((n) => !n.isRead).length;
    return CustomerNotificationsState(
      notifications: mockNotifs,
      unreadCount: unread,
      isLoading: false,
    );
  }

  @override
  Future<void> loadNotifications({bool silent = false}) async {}
}

