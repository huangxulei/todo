import 'package:flutter/material.dart';
import 'package:todo/pages/todo_page.dart';
import 'package:todo/utils/db_util.dart';

void main() async {
  /// 注意：需要添加下面的一行，才可以使用 异步方法
  WidgetsFlutterBinding.ensureInitialized();

  /// 初始化 Hive
  await DBUtil.install();
  await DBUtil.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive Demo',
      theme: ThemeData(
        platform: TargetPlatform.iOS,
        primaryColor: Colors.blueAccent,
        appBarTheme: const AppBarTheme(elevation: 0),
      ),
      home: const TodoPage(),
    );
  }
}
