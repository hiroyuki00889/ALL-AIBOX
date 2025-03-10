import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test_flutter4/data/services/hive_service.dart';
import 'SecondQuestion.dart';
import 'TaskTableScreen.dart';
import 'ProcessDiagramScreen.dart';
import 'dart:math';

/**
 * 悩み相談の結果を表示するためのStatefulWidgetクラス
 * ユーザーの入力した悩みに対してClaudeAPIを使用してアドバイスを生成する
 */
class Result extends StatefulWidget {
  @override
  _ResultState createState() => _ResultState();
}

/**
 * Resultウィジェットの状態を管理するStateクラス
 * HiveデータベースとClaudeAPIの連携を行い、
 * ユーザーの悩みに対するアドバイスを生成・表示する
 */
class _ResultState extends State<Result> {
  // Hiveデータベースサービスのインスタンス
  final hiveService = HiveService();

  // ユーザー入力と質問関連の状態変数
  String input = '';                    // 現在の入力テキスト
  String question = '';                 // 現在の質問
  String firstWorry = '';              // 最初に入力された悩み
  Map<String, String> questionsAndChoices = {};    //質問と選択肢リストから選んだ文章のセットの変数
  List<String> questions = [];         // 質問リスト

  // UI状態管理用の変数
  bool isLoading = false;              // ローディング状態
  String errorMessage = '';            // エラーメッセージ
  String adviceText = '';             // Claudeからのアドバイステキスト
  String adviceText2 = '';            // 追加のアドバイステキスト

  /**
   * ウィジェットの初期化時に実行される処理
   * データの読み込みとClaude APIの呼び出しを行う
   */
  @override
  void initState() {
    super.initState();
    _loadData();
    Future.microtask(() => callClaude());
  }

  /**
   * Hiveデータベースから保存されているデータを読み込む
   * 質問、悩み、要約などの情報を取得してステート変数を更新する
   */
  void _loadData() {
    setState(() {
      question = hiveService.getQuestion();
      questions = hiveService.getQuestions();
      questionsAndChoices = hiveService.getQuestionsAndChoices();
      firstWorry = hiveService.getFirstWorry();
    });
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
- タイトル: 悩みを解決するためのアドバイスプロンプト
- 依頼者条件: 自分の悩みや問題を具体的に理解し、解決策を求めている人。
- 制作者条件: 問題解決に関する知識や経験を持ち、効果的なアドバイスを提供できる人。
- 目的と目標: 悩みや問題を細分化し、具体的な解決策を提示することで、依頼者が自らの問題解決に向けて前進できるようにすること。

#変数設定
最初の悩みポスト="$firstWorry"
今までの質問と答え="$questionsAndChoices"

#この内容を実行してください
{最初の悩みポスト}の問題を解決するためのアドバイスを問題の要素である{今までの質問と答え}を含めて考えて生成してください。
生成する文章に変数名を出さないでください。

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
      print('Response received. Status code: ${response.statusCode}'); // デバッグログ
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('Complete API response: $data'); // レスポンス全体を確認

        // レスポンスの構造を確認
        if (data['content'] != null && data['content'].isNotEmpty) {
          adviceText = data['content'][0]['text'] ?? '';
          print('Advice text length: ${adviceText.length}');
          print('First 100 characters: ${adviceText.substring(0, min(100, adviceText.length))}');
          print('Last 100 characters: ${adviceText.substring(max(0, adviceText.length - 100))}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '悩み・相談解決くん:結果画面',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Container(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                  child: Text(
                    adviceText,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              // ボタン群を追加
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // タスク表作成画面への遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskTableScreen(advice: adviceText),
                        ),
                      );
                    },
                    icon: Icon(Icons.task),
                    label: Text('タスク表\n作成'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // 思考プロセス図作成画面への遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProcessDiagramScreen(advice: adviceText),
                        ),
                      );
                    },
                    icon: Icon(Icons.account_tree),
                    label: Text('思考プロセス\n図作成'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // ホームに戻る
                      Navigator.popUntil(
                          context,
                              (route) => route.isFirst
                      );
                    },
                    icon: Icon(Icons.home),
                    label: Text('ホームに\n戻る'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}