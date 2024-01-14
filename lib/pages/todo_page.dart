import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../db/todo_item_db.dart';
import '../utils/db_util.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({Key key}) : super(key: key);

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  DBUtil dbUtil;

  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    dbUtil = await DBUtil.getInstance();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Hive todo'),
          actions: [
            IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: () async {
                  bool confirm = await confirmAlert('确定清空所有待办？');
                  if (confirm != true) return;
                  await dbUtil.todoBox.clear();
                }),
          ],
        ),
        body: content,
        floatingActionButton: createBtn);
  }

  /// 确认弹窗
  Future<bool> confirmAlert(String content, {String title = '操作提示'}) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text("取消")),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text("确定"))
          ],
        );
      },
    );
  }

  Widget get content {
    if (dbUtil == null || dbUtil.todoBox == null) {
      return Container(
        alignment: Alignment.center,
        child: const Text('Loading'),
      );
    }

    return ValueListenableBuilder(
        valueListenable: dbUtil.todoBox.listenable(),
        builder: (BuildContext context, Box todos, Widget _) {
          if (todos.keys.isEmpty) return empty;
          return lists(todos);
        });
  }

  Widget lists(Box todos) {
    int total = todos.keys.length;

    /// 获取未完成待办
    List<TodoItem> defaults = [];

    /// 获取已完成待办
    List<TodoItem> completions = [];

    for (int i = 0; i < total; i++) {
      TodoItem item = todos.getAt(i);

      if (item.completionAt != null) {
        completions.add(item);
      } else {
        defaults.add(item);
      }
    }

    /// 创建待处理列表
    Widget defaultsList = ListView.builder(
      itemCount: defaults.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext contenx, int index) => row(defaults[index]),
    );

    /// 创建已完成列表
    Widget completionsList = ListView.builder(
      itemCount: completions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext contenx, int index) => row(completions[index]),
    );

    return ListView(
      children: [
        const SizedBox(height: 10),
        defaultsList,
        if (completions.isNotEmpty) completionsList,
        if (total > 0)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: Text(
              '共 $total 条待办',
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// 待办条目
  Widget row(TodoItem item) {
    /// 是否存在优先级
    bool inLevel = item.level != null && item.level > 0;

    /// 是否已完成
    bool isCompletion = item.completionAt != null;

    /// 优先级图标
    Widget levelPrefix = Text(
      '!' * item.level,
      style: TextStyle(color: Colors.red),
    );

    /// 文本内容
    Widget content = Expanded(
      child: Text(
        item.content ?? '未输入内容',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          decoration:
              isCompletion ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
    );

    /// 副标题
    Widget subtitle = Text(
      (isCompletion ? item.completionAt : item.createAt) ?? '-',
    );

    /// 操作
    Widget actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isCompletion)
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: Colors.green),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return TodoCreateDialog(
                      dbUtil: dbUtil,
                      item: item,
                    );
                  });
            },
          ),
        IconButton(
          icon: const Icon(Icons.clear, size: 20, color: Colors.red),
          onPressed: () async {
            bool confirm = await confirmAlert('确定删除本条待办？');
            if (confirm != true) return;
            await dbUtil.todoBox.delete(item.key);
          },
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        isCompletion
            ? Container(width: 24)
            : IconButton(
                //未完成,显示操作按钮
                icon: const Icon(Icons.check_circle,
                    size: 20, color: Colors.blueAccent),
                onPressed: () async {
                  /// 已完成
                  item.completionAt = DateTime.now().toString();
                  await dbUtil.todoBox.put(item.key, item);
                },
              ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (inLevel) levelPrefix,
                  if (inLevel) const SizedBox(width: 10),
                  content,
                ],
              ),
              const SizedBox(height: 8),
              subtitle
            ],
          ),
        ),
        const SizedBox(width: 10),
        actions,
      ]),
    );
  }

  /// 无数据
  Widget get empty {
    return Container(
      alignment: Alignment.center,
      child: const Text('暂无数据'),
    );
  }

  /// 新增按钮
  Widget get createBtn {
    return FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () {
        showDialog(
            context: context,
            builder: (context) {
              return TodoCreateDialog(dbUtil: dbUtil);
            });
      },
    );
  }
}

class TodoCreateDialog extends StatefulWidget {
  /// 从上下文传入 DBUtil，避免再次获取实例
  final DBUtil dbUtil;

  /// 如果传入了一个条目，则视为编辑
  final TodoItem item;

  const TodoCreateDialog({Key key, @required this.dbUtil, this.item})
      : super(key: key);

  @override
  State<TodoCreateDialog> createState() => _TodoCreateDialogState();
}

class _TodoCreateDialogState extends State<TodoCreateDialog> {
  TextEditingController _contentEditingController;
  String content;
  int level;

  @override
  void initState() {
    content = "";
    level = 0;
    _contentEditingController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item != null) {
      print('====这里干什么');
      content = widget.item?.content;
      _contentEditingController.text = content;
      level = widget.item?.level ?? 0;
      setState(() {});
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          title,
          input,
          levelPicker,
          const SizedBox(height: 20),
          const Divider(),
          actions,
        ],
      ),
    );
  }

  /// 标题
  Widget get title {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
      width: double.infinity,
      child: Text(
        widget.item != null ? '编辑待办' : '新建待办',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 输入框
  Widget get input {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey.withAlpha(70)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          TextField(
            minLines: 2,
            maxLines: 8,
            controller: _contentEditingController,
            decoration: const InputDecoration(
              hintText: '请填写待办事项',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (String value) {
              setState(() {
                content = value;
              });
            },
          ),
        ],
      ),
    );
  }

  /// 优先级
  Widget get levelPicker {
    return Row(
      children: [
        const SizedBox(width: 20),
        const Expanded(
          child: Text(
            '优先级',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
        ),
        CupertinoSegmentedControl<int>(
          groupValue: level,
          borderColor: Colors.green,
          selectedColor: Colors.green,
          padding: EdgeInsets.zero,
          children: const {
            0: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('正常'),
            ),
            1: Text('高'),
            2: Text('紧急'),
          },
          onValueChanged: (int index) {
            setState(() {
              level = index;
            });
          },
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget get actions {
    return Container(
      padding: const EdgeInsets.only(
        right: 20,
        left: 20,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: cancelBtn),
          Expanded(child: confirmBtn),
        ],
      ),
    );
  }

  /// 取消按钮
  Widget get cancelBtn {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: const Text(
        '取消',
        style: TextStyle(
          fontSize: 16,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  /// 创建按钮
  Widget get confirmBtn {
    return TextButton(
      onPressed: () async {
        if (widget.item != null) {
          /// 更新
          await widget.dbUtil.todoBox.put(
            widget.item.key,
            TodoItem(
              content: content,
              level: level ?? 0,
              createAt: widget.item.createAt,
              completionAt: widget.item.completionAt,
            ),
          );
        } else {
          /// 新增
          await widget.dbUtil.todoBox.add(TodoItem(
            content: content,
            level: level ?? 0,
            createAt: DateTime.now().toString(),
          ));
        }
        Navigator.of(context).pop();
      },
      child: Text(
        widget.item != null ? '保存' : '创建',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
