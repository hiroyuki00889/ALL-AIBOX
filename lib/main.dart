import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:test_flutter4/Hive.dart';
import 'screens/SecondQuestion.dart';

/** アプリケーションのエントリーポイント
 * Firebaseの初期化と環境設定を行い、
 * 初期画面を表示する
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await dotenv.load(fileName: ".env");
    runApp(MaterialApp(home: FirstQuestion(),));
  } catch(e) {
    print('Error initializing app: $e');
    runApp(MaterialApp(home: ErrorScreen(error: e.toString())));
  }
}

/** エラー画面を表示するウィジェット
 * @param error 表示するエラーメッセージ
 */
class ErrorScreen extends StatelessWidget {
  final String error;
  ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('An error occurred: $error')),
    );
  }
}

/** 最初の質問画面を表示するウィジェット */
class FirstQuestion extends StatefulWidget {
  @override
  _FirstQuestionState createState() => _FirstQuestionState();
}

/** FirstQuestionの状態を管理するクラス */
class _FirstQuestionState extends State<FirstQuestion> {
  final hiveService = HiveService();         //Hiveサービスのインスタンス
  String input = '';                         //ユーザー入力を保持する変数
  String question = '';                      //現在の質問を保持する変数
  List<String> questions = [];               //質問リストを保持する変数
  List<String> choices = [];                 //選択肢リストを保持する変数
  bool isLoading = false;                    //ローディング状態を示すフラグ
  String errorMessage = '';                  //エラーメッセージを保持する変数
  Color color = Color(0xFF4A4A4A);            //アプリケーションの基本カラー
  Color buttonColor = Color(0xFF614051);      //ボタンのカラー

  /** 初期化処理
   * Hiveの初期化を行う
   */
  @override
  void initState() {
    super.initState();
    hiveService.initHive();
  }

  /** インターネット接続を確認する
   * @return インターネットに接続されているかどうか
   */
  Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  /** Claude APIを呼び出し、質問を生成する
   * APIキーの検証、インターネット接続の確認、
   * レスポンスの処理を行う
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
    //　セーブしたデータの消去
    hiveService.clearAllData();

    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      print('Calling Claude API...');

      // 環境変数からAPIキーを取得
      final apikey = dotenv.env['API_KEY'];
      if (apikey == null) {
        throw Exception('API_KEY not found in .env file');
      }
      // APIエンドポイントの設定
      final url = Uri.parse('https://api.anthropic.com/v1/messages');
      print('API Key loaded successfully');

      /** APIに送信するプロンプトテンプレート */
      final prompt = '''
#前提条件
タイトル: 悩みや問題を聞いて核心に迫る質問を生成するプロンプト
依頼者条件: 悩みや問題を解決したい人、悩みや問題の要因を明らかにしたい人
制作者条件: 悩みや問題解決の知識がある人、コーチングやカウンセリングの知識がある人

目的と目標: 依頼者が相手の本質や真意に迫る質問を作成できるよう支援するためのプロンプトを提供する。具体的な目標は、質問の明快さ、深さ、効果的なコミュニケーションへの貢献度を高めること。

リソース: 5W1H、ジャーナリング、コーチングやカウンセリングの手法、問題解決の書籍

評価基準: 生成された質問が相手の悩みや問題の要因を明らかにするものか、質問の構造が適切か、相手の悩みや問題の構造に気付けるような質問か、質問が問題解決の効果があったかどうか

明確化の要件:
1. 質問は相手の感情や思考に寄り添ったものであること
2. 質問は原因を切り分けるものであること
3. 質問は具体的であること、抽象的すぎないこと
4. 質問は相手に対する尊重と信頼を示すものであること
5. 質問は自己中心的ではなく、相手中心であること

#変数設定

悩みポスト="$input"

#この内容を実行してください
step1:
{悩みポスト}の内容から
悩みの核心に迫る質問を{質問}に、悩みの要因を明らかにする質問を{質問リスト}に従いリスト変数に入れる形式で生成してください。
話しかける文体で生成してください。
1つの質問ごとに,を入れてください。
不用意な番号や記号は書かないでください。

質問 = "質問={}"
質問リスト = "質問リスト={ , , , , , ,}"

step2:
{質問}に生成した質問に対しての回答の選択肢を３つ生成して{選択肢}に従い変数に入れる形式で生成してください
選択肢 = "選択肢={ , , ,}"
''';
      // リクエストボディの準備
      print('Preparing request body...'); //
      final body = jsonEncode({
        "model": "claude-3-5-sonnet-20240620",
        "max_tokens": 2000,
        "messages": [
          {"role": "user", "content": prompt}
        ],
      });
      // APIリクエストの送信
      print('Sending request to Claude API...'); //
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
      print('Response received. Status code: ${response.statusCode}'); //
      if (response.statusCode == 200) {
        print('Successful response. Processing data...'); //
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('Raw API response: ${data['content'][0]['text']}');
        _processResponse(data['content'][0]['text']);
        print('Response processed successfully'); //
      } else {
        print('Error response. Body: ${response.body}'); //
        throw Exception('Failed to load data: ${response.statusCode}, ${response.body}');
      }
    }catch (e, stackTrace) {
      // エラーハンドリング
      print('Error in callClaude: $e'); //
      print('Stack trace: $stackTrace');
    } finally {
      // 処理完了後のクリーンアップ
      setState(() {
        isLoading = false;
      });
      print('API call completed'); //
    }
    await hiveService.saveQuestionsData(questions, question);
    await hiveService.saveFirstWorry(input);
    await hiveService.saveStageNumber(0,0);
    await hiveService.saveChoices(choices);
  }
  /** APIレスポンスを処理する
   * @param responseText APIからのレスポンステキスト
   * 質問リスト、質問、悩み要約を抽出し、状態を更新する
   */
  void _processResponse(String responseText) {
    print('_processResponse実行 Processing response: $responseText');
    final questionsMatch = RegExp(r'質問リスト=\{([^}]*)\}').firstMatch(responseText);
    final questionMatch = RegExp(r'質問=\{(.*?)\}').firstMatch(responseText);
    final choicesMatch = RegExp(r'選択肢=\{([^}]*)\}').firstMatch(responseText);

    setState(() {
    if (questionsMatch != null) {
      questions = questionsMatch.group(1)!.split(',').map((e) => e.trim()).toList();
    }else {
      print('No questions found in the response'); // 追加：質問が見つからない場合のログ
    }

    if(questionMatch != null){
      question = questionMatch.group(1)!;
      questions.remove(question);
    }else{
      print('No question found in the response');
    }

    if (choicesMatch != null) {
      choices.addAll(choicesMatch.group(1)!.split(',').map((e) => e.trim()).toList());
    } else {
      print('No _choices found in the response'); // 追加：選択肢が見つからない場合のログ
    }

    if (questions.isEmpty && question.isEmpty) {
      errorMessage = '有効な応答を受け取れませんでした。入力を確認してやり直してください。';
      print('No valid data found in the response'); // 追加：有効なデータが見つからない場合のログ
    }
    print('Processed questions: $questions'); // 追加：処理後の質問をログ出力
    //print('Processed worry elements: $_worryElements'); // 追加：処理後の悩み要素をログ出力
    });
  }
  /** ウィジェットをビルドする
   * @param context ビルドコンテキスト
   * @return アプリケーションのUI
   */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('悩み・相談解決くん',
                  style: TextStyle(color: Colors.white),),
          backgroundColor: color,
      ),
      body: Container(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                minLines: 1,
                maxLines: null,
                onChanged: (value) => input = value,
                decoration: InputDecoration(labelText: '悩みを入力してください'),
                style: TextStyle(color: color.withOpacity(0.7)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor.withOpacity(0.7),
                  foregroundColor: Colors.white,
                ),
                onPressed: isLoading ? null
                    : () async {
                  await callClaude();
                  if(question.isNotEmpty){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SecondQuestion(question: question,)),
                    ); //trueの時_is..をnullにfalseの時callClaude実行
                  }else{
                    // エラーハンドリング（例：スナックバーでエラーメッセージを表示）
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('質問の生成に失敗しました。もう一度お試しください。')),
                    );
                  }
                },
                child: isLoading ? CircularProgressIndicator() : Text('分析する'), //true:CircularP..,false:Text
              ),
            ],
          ),
        ),
      )

    );
  }
}