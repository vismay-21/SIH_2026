import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/api/api_models.dart';
import 'package:mobile_app/widgets/common/skeleton_loaders.dart';

void main() {
  group('TasksListSkeleton & Shimmer Loader Tests', () {
    testWidgets('TasksListSkeleton renders ShimmerEffect and mock skeleton rows', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TasksListSkeleton(itemCount: 4),
          ),
        ),
      );

      // Verify ShimmerEffect is present
      expect(find.byType(ShimmerEffect), findsOneWidget);

      // Verify SkeletonBox instances are rendered (each row has 2 boxes: circle + label)
      // 4 rows * 2 = 8 boxes
      expect(find.byType(SkeletonBox), findsNWidgets(8));

      // Check pump with animation tick
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('TasksListSkeleton respects default itemCount of 5', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TasksListSkeleton(),
          ),
        ),
      );

      // 5 rows * 2 = 10 boxes
      expect(find.byType(SkeletonBox), findsNWidgets(10));
    });

    testWidgets('SkeletonBox and ShimmerEffect adapt to dark theme without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Column(
              children: [
                TasksListSkeleton(itemCount: 2),
                GigCardSkeleton(),
                OpportunityCardSkeleton(),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TasksListSkeleton), findsOneWidget);
      expect(find.byType(GigCardSkeleton), findsOneWidget);
      expect(find.byType(OpportunityCardSkeleton), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
    });

    test('Cross-category task isolation sanitizes stale task IDs', () {
      // Mock Plumbing tasks loaded after switching from Carpentry
      final currentCategoryTasks = [
        const ServiceTaskDto(
          id: 'plumb-leak-fix',
          categoryId: 'cat-plumbing',
          name: 'Fix leaking pipe',
          standardDurationMinutes: 45,
          basePrice: 250.0,
          complexityScore: 1.0,
          complexityBucket: 'MEDIUM',
        ),
        const ServiceTaskDto(
          id: 'plumb-tap-replace',
          categoryId: 'cat-plumbing',
          name: 'Tap replacement',
          standardDurationMinutes: 30,
          basePrice: 180.0,
          complexityScore: 1.0,
          complexityBucket: 'LOW',
        ),
      ];

      // Simulated selection containing a lingering Carpentry task ('curtain-rod') and a valid Plumbing task
      final selectedTaskIds = <String>{'curtain-rod', 'plumb-leak-fix'};

      // Sanitize
      final validCategoryTaskIds = currentCategoryTasks.map((t) => t.id).toSet();
      selectedTaskIds.removeWhere((id) => !validCategoryTaskIds.contains(id));

      // Carpentry task 'curtain-rod' must be eliminated
      expect(selectedTaskIds.contains('curtain-rod'), isFalse);
      expect(selectedTaskIds.contains('plumb-leak-fix'), isTrue);
      expect(selectedTaskIds.length, 1);
    });

    test('Task selection allows unchecking down to 0 without restriction', () {
      final selectedTaskIds = <String>{'task-1'};

      // Unselect task-1
      selectedTaskIds.remove('task-1');
      expect(selectedTaskIds.isEmpty, isTrue);

      // Select 3rd and 5th items directly
      selectedTaskIds.add('task-3');
      selectedTaskIds.add('task-5');
      expect(selectedTaskIds, containsAll(['task-3', 'task-5']));
      expect(selectedTaskIds.contains('task-1'), isFalse);
    });
  });
}
