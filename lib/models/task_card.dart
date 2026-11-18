class TaskCard {
  final int id;
  String title;
  String details;
  DateTime dueAt;
  int level; // 0 مهم، 1 ضروري، 2 ضروري جداً
  bool locked;
  bool done;

  TaskCard({
    required this.id,
    required this.title,
    this.details = '',
    required this.dueAt,
    this.level = 0,
    this.locked = false,
    this.done = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'details': details,
        'dueAt': dueAt.millisecondsSinceEpoch,
        'level': level,
        'locked': locked,
        'done': done,
      };

  factory TaskCard.fromMap(Map<String, dynamic> m) => TaskCard(
        id: m['id'] as int,
        title: m['title'] as String,
        details: (m['details'] as String?) ?? '',
        dueAt: DateTime.fromMillisecondsSinceEpoch(m['dueAt'] as int),
        level: ((m['level'] as int?) ?? 0).clamp(0, 2).toInt(),
        locked: (m['locked'] as bool?) ?? false,
        done: (m['done'] as bool?) ?? false,
      );
}
