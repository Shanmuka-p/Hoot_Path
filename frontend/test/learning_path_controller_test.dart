import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoot_path/controllers/learning_path_controller.dart';

void main() {
  group('LearningPathController Tier Classification', () {
    late LearningPathController controller;

    setUp(() {
      controller = LearningPathController(
        userId: 'test_user',
        currentAccuracy: {},
      );
    });

    test('tierLabel returns correct label for percentage', () {
      expect(controller.tierLabel(30.0), 'Critical');
      expect(controller.tierLabel(50.0), 'Weak');
      expect(controller.tierLabel(70.0), 'Moderate');
      expect(controller.tierLabel(85.0), 'Good');
      expect(controller.tierLabel(95.0), 'Strong');
    });

    test('tierColor returns correct color for percentage', () {
      expect(controller.tierColor(30.0), const Color(0xFFD32F2F)); // Critical
      expect(controller.tierColor(50.0), const Color(0xFFE65100)); // Weak
      expect(controller.tierColor(70.0), const Color(0xFFF9A825)); // Moderate
      expect(controller.tierColor(85.0), const Color(0xFF388E3C)); // Good
      expect(controller.tierColor(95.0), const Color(0xFF1565C0)); // Strong
    });

    test('priority returns correct value for percentage', () {
      expect(controller.priority(30.0), 5); // Critical
      expect(controller.priority(50.0), 4); // Weak
      expect(controller.priority(70.0), 3); // Moderate
      expect(controller.priority(85.0), 2); // Good
      expect(controller.priority(95.0), 1); // Strong
    });
  });
}
