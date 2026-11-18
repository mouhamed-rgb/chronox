import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/models/task_card.dart';

void main() {
  test('TaskCard survives a storage map round trip', () {
    final original = TaskCard(
      id: 12345,
      title: 'مراجعة الدرس',
      details: 'الفصل الثاني',
      dueAt: DateTime(2026, 11, 20, 18, 30),
      level: 2,
      locked: true,
      done: false,
    );

    final restored = TaskCard.fromMap(original.toMap());
    expect(restored.id, original.id);
    expect(restored.title, original.title);
    expect(restored.details, original.details);
    expect(restored.dueAt, original.dueAt);
    expect(restored.level, original.level);
    expect(restored.locked, isTrue);
    expect(restored.done, isFalse);
  });
}
