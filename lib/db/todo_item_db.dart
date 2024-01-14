import 'package:hive/hive.dart';

class TodoItem extends HiveObject {
  String content;
  int level;
  String createAt;
  String completionAt;

  TodoItem({this.content, this.level, this.createAt, this.completionAt});
}

class TodoItemAdapter extends TypeAdapter<TodoItem> {
  @override
  final int typeId = 0;

  @override
  TodoItem read(BinaryReader reader) {
    return TodoItem(
        content: reader.read(),
        level: reader.read(),
        createAt: reader.read(),
        completionAt: reader.read());
  }

  @override
  void write(BinaryWriter writer, TodoItem obj) {
    writer.write(obj.content);
    writer.write(obj.level ?? 0);
    writer.write(obj.createAt ?? DateTime.now().toString());
    writer.write(obj.completionAt);
  }
}
