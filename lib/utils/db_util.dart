import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../db/todo_item_db.dart';

/// 1.实例化一个 instance
/// 2.建一个Box
/// 3.异步获取这个 instance

class DBUtil {
  static DBUtil instance;

  Box todoBox;

  /// 初始化，需要在 main.dart 调用
  /// <https://docs.hivedb.dev/>
  static Future<void> install() async {
    /// 初始化数据库地址
    Directory document = await getApplicationDocumentsDirectory();
    Hive.init(document.path);
    //引入结构
    Hive.registerAdapter(TodoItemAdapter());
  }

  //获取实例
  static Future<DBUtil> getInstance() async {
    if (instance == null) {
      // 判断是否存在,防止多个
      instance = DBUtil(); // 初始化
      //数据库存放地址
      await Hive.initFlutter();

      instance.todoBox = await Hive.openBox('todo');
    }
    return instance;
  }
}
