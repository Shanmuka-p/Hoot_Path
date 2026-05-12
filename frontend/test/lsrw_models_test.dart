import 'package:flutter_test/flutter_test.dart';
import 'package:hoot_path/models/lsrw_models.dart';

void main() {
  group('LSRW Models', () {
    test('OverallSkill.fromJson parses correctly', () {
      final json = {
        'module': 'Listening',
        'count': 5,
        'duration': 120,
        'accuracy': 85.5,
        'percentage': 85.5,
        '_id': '123'
      };

      final skill = OverallSkill.fromJson(json);

      expect(skill.module, 'Listening');
      expect(skill.count, 5);
      expect(skill.duration, 120);
      expect(skill.accuracy, 85.5);
      expect(skill.percentage, 85.5);
      expect(skill.id, '123');
    });

    test('OverallLsrwData calculates overallPercentage correctly', () {
      final skills = [
        OverallSkill(module: 'Listening', count: 1, duration: 1, accuracy: 80, percentage: 80, id: '1'),
        OverallSkill(module: 'Speaking', count: 1, duration: 1, accuracy: 90, percentage: 90, id: '2'),
        OverallSkill(module: 'Reading', count: 1, duration: 1, accuracy: 70, percentage: 70, id: '3'),
        OverallSkill(module: 'Writing', count: 1, duration: 1, accuracy: 60, percentage: 60, id: '4'),
      ];

      final data = OverallLsrwData(skills: skills);

      expect(data.overallPercentage, 75.0);
      expect(data.listening?.module, 'Listening');
    });

    test('ModuleRecord.fromJson resolves icon URL', () {
      final json = {
        'module_name': 'Test Module',
        'module_icon': '/icon.png',
        'complexity': 'medium',
        'percentage': 50,
        'count': 2,
        'course_name': 'Test Course'
      };

      final record = ModuleRecord.fromJson(json, 'https://aihoot.in');
      expect(record.moduleIcon, 'https://aihoot.in/icon.png');
      expect(record.percentage, 50.0);
      expect(record.complexity, 'medium');
    });
  });
}
