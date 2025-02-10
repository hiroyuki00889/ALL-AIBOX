import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test_flutter4/Hive.dart';
import 'Result.dart';

/**　タスク表を出力するためのStatefulWidgetクラス
 * 　出力したアドバイスからClaudeAPIでタスク表を作り出す。
 */
class TaskTableScreen extends StatefulWidget {
  @override
  _TaskTableScreenState createState() => _TaskTableScreenState();
}

/**　TaskTableScreenウィジットの状態を管理するクラス
 * 　HiveデータベースとClaudeAPIを使い、タスク表を作る
 */
class _TaskTableScreenState extends State<TaskTableScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text(
      '悩み・相談解決くん',
      style: TextStyle(color: Colors.black),
      ),
      )
    );
  }
}