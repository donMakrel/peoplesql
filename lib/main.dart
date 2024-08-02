import 'package:flutter/material.dart';
import 'package:peoplesql/group_screen.dart';
import 'package:peoplesql/main_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'People and Groups Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(),
      routes: {
        '/groups': (context) => GroupScreen(),
      },
    );
  }
}