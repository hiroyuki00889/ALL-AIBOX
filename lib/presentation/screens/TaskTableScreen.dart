import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test_flutter4/data/services/hive_service.dart';
import 'Result.dart';
import 'dart:math';

/**　タスク表を出力するためのStatefulWidgetクラス
 * 　出力したアドバイスからClaudeAPIでタスク表を作り出す。
 */
class TaskTableScreen extends StatefulWidget {
  final String advice;
  const TaskTableScreen({super.key, required this.advice});
  @override
  _TaskTableScreenState createState() => _TaskTableScreenState();
}

/**　TaskTableScreenウィジットの状態を管理するクラス
 * 　HiveデータベースとClaudeAPIを使い、タスク表を作る
 */
class _TaskTableScreenState extends State<TaskTableScreen> {
  // Hiveデータベースサービスのインスタンス
  final hiveService = HiveService();

  // UI状態管理用の変数
  bool isLoading = false;              // ローディング状態
  String errorMessage = '';            // エラーメッセージ
  List<String> tasks = [];

  /**
   * ウィジェットの初期化時に実行される処理
   * データの読み込みとClaude APIの呼び出しを行う
   */
  @override
  void initState() {
    super.initState();
    Future.microtask(() => callClaude());
  }

  /** インターネット接続を確認する
   * @return インターネットに接続されているかどうか
   */
  Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  /**
   * Claude APIを呼び出してアドバイスを生成する非同期関数
   * APIキーの検証、リクエストの作成、レスポンスの処理を行う
   * エラーハンドリングとローディング状態の管理も実装
   */
  Future<void> callClaude() async {
    // 既に処理中の場合は早期リターン
    if (isLoading) return;

    //　インターネット接続確認
    if (!await checkInternetConnection()) {
      setState(() {
        errorMessage = 'インターネット接続がありません。接続を確認してください。';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('Calling Claude API...'); // デバッグログ

      // 環境変数からAPIキーを取得
      final apikey = dotenv.env['API_KEY'];
      if (apikey == null) {
        throw Exception('API_KEY not found in .env file');
      }

      // APIエンドポイントの設定
      final url = Uri.parse('https://api.anthropic.com/v1/messages');
      print('API Key loaded successfully'); // デバッグログ

      // プロンプトの構築
      final prompt = '''
#前提条件:
- タイトル: アドバイス文章からタスク表を作成するプロンプト
- 依頼者条件: タスク管理やプロジェクトの進行を効率化したい人。
- 制作者条件: 論理的思考力と文章構成能力を持つ人。
- 目的と目標: アドバイス文章を基に、具体的なタスク表を作成し、実行可能なアクションプランを提供すること。

アドバイス文章="${widget.advice}"
{アドバイス文章}を基にタスク表を作成してください。
''';

      // リクエストボディの準備
      print('Preparing request body...'); // デバッグログ
      final body = jsonEncode({
        "model": "claude-3-5-sonnet-20240620",
        "max_tokens": 8096,
        "messages": [
          {"role": "user", "content": prompt}
        ],
      });

      // APIリクエストの送信
      print('Sending request to Claude API...'); // デバッグログ
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apikey,
          'anthropic-version': '2023-06-01'
        },
        body: body,
      );

      // レスポンスの処理
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('Complete API response: $data'); // レスポンス全体を確認

        /* レスポンスの構造を確認
         * TaskTableScreen用タスク抽出リスト変数化
         */
        if (data['content'] != null && data['content'].isNotEmpty) {
          String rawText = data['content'][0]['text'] ?? '';
          setState(() {
            tasks = extractTasks(rawText);
          });
        } else {
          throw Exception('Invalid response structure');
        }
      }
    } catch (e, stackTrace) {
      // エラーハンドリング
      print('Error in callClaude: $e'); // デバッグログ
      print('Stack trace: $stackTrace');
    } finally {
      // 処理完了後のクリーンアップ
      setState(() {
        isLoading = false;
      });
      print('API call completed'); // デバッグログ
    }
  }
    //タスク表のタスクの部分を抽出する関数（正規表現）
    List<String> extractTasks(String rawText) {
      RegExp regExp = RegExp(r'\d+\.\s(.*?)\n\s*- (.*?)\n', multiLine: true);
      return regExp.allMatches(rawText).map((match) {
        return '${match.group(1)} - ${match.group(2)}';
      }).toList();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
            title: Text('タスク表', style: TextStyle(color: Colors.black))),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? Center(
            child: Text(errorMessage, style: TextStyle(color: Colors.red)))
            : ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                leading: Icon(Icons.task),
                title: Text(tasks[index]),
              ),
            );
          },
        ),
      );
    }
}