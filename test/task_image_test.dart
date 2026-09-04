import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staff_checkin/models/check_task_model.dart';
import 'package:staff_checkin/widgets/media_preview_widget.dart';
import 'package:staff_checkin/widgets/task_item_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CheckTaskModel imageUrl Field Tests', () {
    test('CheckTaskModel defaults imageUrl to empty string', () {
      const task = CheckTaskModel(
        stepNumber: 1,
        title: 'Floor Check',
        requirementType: RequirementType.photo,
      );
      expect(task.imageUrl, isEmpty);
    });

    test('CheckTaskModel.fromMap reads imageUrl correctly', () {
      final task = CheckTaskModel.fromMap({
        'taskName': 'Clean Countertop',
        'mediaType': 'photo',
        'imageUrl': 'https://example.com/countertop_guide.png',
      }, 0);

      expect(task.imageUrl, equals('https://example.com/countertop_guide.png'));
    });

    test('CheckTaskModel.fromMap also falls back to image key if present', () {
      final task = CheckTaskModel.fromMap({
        'taskName': 'Clean Kitchen',
        'mediaType': 'video',
        'image': 'https://example.com/kitchen_guide.png',
      }, 1);

      expect(task.imageUrl, equals('https://example.com/kitchen_guide.png'));
    });

    test('CheckTaskModel.toMap and copyWith preserve imageUrl', () {
      const task = CheckTaskModel(
        stepNumber: 2,
        title: 'Freezer Clean',
        requirementType: RequirementType.photo,
        imageUrl: 'https://example.com/freezer.jpg',
      );

      expect(task.toMap()['imageUrl'], equals('https://example.com/freezer.jpg'));

      final updated = task.copyWith(imageUrl: 'https://example.com/freezer_new.jpg');
      expect(updated.imageUrl, equals('https://example.com/freezer_new.jpg'));
    });
  });

  group('TaskItemCard Image and Preview Tests', () {
    testWidgets('Renders normally without thumbnail when imageUrl is empty',
        (tester) async {
      const taskWithoutImage = CheckTaskModel(
        stepNumber: 1,
        title: 'Toppings Bar Cleaning',
        description: 'Sanitize the toppings bar area thoroughly.',
        requirementType: RequirementType.photo,
        imageUrl: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskItemCard(
              task: taskWithoutImage,
              onCapture: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Toppings Bar Cleaning'), findsOneWidget);
      expect(find.text('Sanitize the toppings bar area thoroughly.'), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen_rounded), findsNothing);
    });

    testWidgets(
        'Renders side thumbnail and opens MediaPreviewDialog on tap when imageUrl is present',
        (tester) async {
      const taskWithImage = CheckTaskModel(
        stepNumber: 1,
        title: 'Nozzle Inspection',
        description: 'Check yoghurt nozzles for residue.',
        requirementType: RequirementType.photo,
        imageUrl: 'assets/images/ic_check.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskItemCard(
              task: taskWithImage,
              onCapture: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Side thumbnail fullscreen icon is visible
      expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);

      // Tap on thumbnail
      await tester.tap(find.byIcon(Icons.fullscreen_rounded));
      await tester.pumpAndSettle();

      // Verify MediaPreviewDialog opens with title
      expect(find.byType(MediaPreviewDialog), findsOneWidget);
      expect(find.text('Nozzle Inspection'), findsWidgets);
    });
  });
}
