enum Priority { necessary, important, critical }
class Task {
 final int? id; final String title,description; final DateTime dueAt; final Priority priority; final bool locked,completed;
 const Task({this.id,required this.title,this.description='',required this.dueAt,this.priority=Priority.important,this.locked=false,this.completed=false});
 Task copy({int? id,String? title,String? description,DateTime? dueAt,Priority? priority,bool? locked,bool? completed})=>Task(id:id??this.id,title:title??this.title,description:description??this.description,dueAt:dueAt??this.dueAt,priority:priority??this.priority,locked:locked??this.locked,completed:completed??this.completed);
 Map<String,Object?> map()=>{'id':id,'title':title,'description':description,'due':dueAt.millisecondsSinceEpoch,'priority':priority.index,'locked':locked?1:0,'completed':completed?1:0};
 factory Task.from(Map<String,Object?> m)=>Task(id:m['id'] as int,title:m['title'] as String,description:m['description'] as String,dueAt:DateTime.fromMillisecondsSinceEpoch(m['due'] as int),priority:Priority.values[m['priority'] as int],locked:m['locked']==1,completed:m['completed']==1);
}