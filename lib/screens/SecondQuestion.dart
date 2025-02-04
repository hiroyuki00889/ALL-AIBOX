import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test_flutter4/Hive.dart';
import 'package:test_flutter4/main.dart';
import 'Result.dart';

/** 第二質問画面を表示するウィジェット
 * @param question 表示する質問文
 */
class SecondQuestion extends StatefulWidget{
  final String question;
  const SecondQuestion({super.key, required this.question});

  @override
  _SecondQuestionState createState() => _SecondQuestionState();
}

/** SecondQuestionの状態を管理するクラス */
class _SecondQuestionState extends State<SecondQuestion>{
  final hiveService = HiveService();   //Hiveサービスのインスタンス
  String question = '';               //現在の質問を保持する変数
  String firstWorry = '';             //最初の悩みを保持する変数
  List<String> questions = [];        //質問リストを保持する変数
  List<String> choices = [];          //選択肢リストを保持する変数
  Map<String, String> questionsAndChoices = {};    //質問と選択肢リストから選んだ文章のセットの変数
  String choice = '';                            //前から選ばれた選択肢の文章
  bool isLoading = false;             //ローディング状態を示すフラグ
  String errorMessage = '';           //エラーメッセージを保持する変数
  int stageNumber = 0;                //現在のステージ番号
  int questionCount = 0;               //質問カウント
  /** セラピーの段階に応じた色のリスト */
  final List<Color> therapyColors = [
    Color(0xFF614051), // 深い紫
    Color(0xFF1B4B66), // 深いブルー
    Color(0xFF256D85), // やや明るい青
    Color(0xFF2E8B57), // シーグリーン
    Color(0xFF90B77D), // やさしい緑
  ];

  /** インターネット接続を確認する
   * @return インターネットに接続されているかどうか
   */
  Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  /** 初期化処理
   * データのロードを行う
   */
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /** 保存されているデータをロードする
   * Hiveから各種データを取得し、状態を更新する
   */
  void _loadData() {
    setState(() {
      question = hiveService.getQuestion();
      questions = hiveService.getQuestions();
      questionsAndChoices = hiveService.getQuestionsAndChoices();
      stageNumber = hiveService.getStageNumber();
      questionCount = hiveService.getQuestionCount();
      choices = hiveService.getChoices();
      firstWorry = hiveService.getFirstWorry();
    });
  }

  /** 現在のステージに対応する色を取得する
   * @return ステージに応じた色
   */
  Color get color => therapyColors[stageNumber % therapyColors.length];

  /** ボタンの色を取得する
   * @return ボタンの色
   */
  Color get buttonColor => therapyColors[stageNumber+1 % therapyColors.length];

  /** Claude APIを呼び出し、質問を生成する
   * 要因の明確化の進捗に応じて次の質問と選択肢を生成する
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

    print("_stageNumberの中身：");
    print(stageNumber);
    print("_questionsの中身：");
    print(questions);
    print("_firstWorryの中身：");
    print(firstWorry);
    print("questionsAndChoicesの中身：");
    questionsAndChoices.forEach((key, value) {
      print('Key: $key, Value: $value');
    });
    //処理中の変数適用、エラーメッセージ空にする
    setState(() {
      isLoading = true;
      errorMessage = '';
      choice = hiveService.getChoice();
    });

    try {
      print('Calling Claude API...'); //デバック

      // 環境変数からAPIキーを取得
      final apikey = dotenv.env['API_KEY'];
      if (apikey == null) {
        throw Exception('API_KEY not found in .env file');
      }

      // APIエンドポイントの設定
      final url = Uri.parse('https://api.anthropic.com/v1/messages');
      print('API Key loaded successfully'); //

      //　プロンプトの構築
      final prompt = '''
#前提条件
タイトル: 悩みや問題からその要因を明らかにする質問と選択肢を生成するプロンプト
依頼者条件: 悩みや問題を解決したい人、悩みや問題の要因を明らかにしたい人
制作者条件: 質問を効果的に構築し、選択肢を提供できるスキルを持つ人。

目的と目標: 悩みや問題の根本的な要因を特定し、解決策を見出すための具体的な質問と選択肢を生成すること。

#変数設定

最初の悩みポスト="$firstWorry"
選んだ選択肢="$choice"
今までの質問と答え="$questionsAndChoices"

#この内容を実行してください
{今までの質問と答え}から考えて{最初の悩みポスト}に対する要因が明らかになった割合を
10％未満なら0、10～29％なら1、30～49％なら2、50～69％なら3　を{何番目}に従い変数に入れる形式で生成してください。

何番目 = "何番目={}"
もし相談者の悩みに対する要因が明らかになった割合を70％以上にできたなら以下のstepを全てスキップして
何番目={4}
と生成してください。

全てのstepで不用意な番号や記号は書かないでください。
step1:
{今までの質問と答え}の内容から
{最初の悩みポスト}の悩みの要因を明らかにする質問を{質問リスト}に従いリスト変数に入れる形式で生成してください。
{今までの質問と答え}のkeyにある内容と被らないようにしてください。
話しかける文章で生成してください。
語尾に思いますかを付けないでください。
1つの質問ごとに,を入れてください。

質問リスト = "質問リスト={ , , , }"

step2:
{質問リスト}とstep1で生成した要素の中から相談者に対して問題解決の助けになる質問を１つ選んで{質問}に従い変数に入れる形式で生成してください。
選んだ質問に対しての回答の選択肢を３つ生成して{選択肢}に従い変数に入れる形式で生成してください。

質問 = "質問={}"
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
        processResponse(data['content'][0]['text']);
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
    await questionCount++;
    await hiveService.saveQuestionsData(questions, question);
    await hiveService.saveQuestionsAndChoices(question, choice);
    await hiveService.saveChoices(choices);
    await hiveService.saveStageNumber(stageNumber, questionCount);
  }
  /** APIレスポンスを処理する
   * @param responseText APIからのレスポンステキスト
   * 質問リスト、質問、選択肢、要約、ステージ番号を抽出し、状態を更新する
   */
  void processResponse(String responseText) {
    print('_processResponse実行 Processing response: $responseText');
    final questionsMatch = RegExp(r'質問リスト=\{([^}]*)\}').firstMatch(responseText);
    final questionMatch = RegExp(r'質問=\{(.*?)\}').firstMatch(responseText);
    final choicesMatch = RegExp(r'選択肢=\{([^}]*)\}').firstMatch(responseText);
    final stageNumberMatch = RegExp(r'何番目=\{(.*?)\}').firstMatch(responseText);

    setState(() {
      if (questionsMatch != null) {
        questions.addAll(questionsMatch.group(1)!.split(',').map((e) => e.trim()).toList());
      } else {
        print('No questions found in the response'); // 追加：質問が見つからない場合のログ
      }

      if (questionMatch != null) {
        question = questionMatch.group(1)!;
        questions.remove(question);
      } else {
        print('No question found in the response');
      }

      if (choicesMatch != null) {
        choices.clear();
        choices.addAll(choicesMatch.group(1)!.split(',').map((e) => e.trim()).toList());
      } else {
        print('No _choices found in the response'); // 追加：選択肢が見つからない場合のログ
      }

      if (stageNumberMatch != null) stageNumber = int.parse(stageNumberMatch.group(1)!);

      if (questions.isEmpty && question.isEmpty) {
        errorMessage =
        '有効な応答を受け取れませんでした。入力を確認してやり直してください。';
        print('No valid data found in the response'); // 追加：有効なデータが見つからない場合のログ
      }
    });
  }

  /** ウィジットをビルドする
   * @pram　context　ビルドコンテキスト
   * @return　アプリケーションのUI
   */
  @override
  Widget build(BuildContext context){
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
              Text(widget.question), //前から選んだ質問といかけ
              SizedBox(height: 20),
              Column(
                //選択肢の分割、ボタンの生成
                children: choices.map((choice) {
                  return ElevatedButton(
                    //押したらローディング中でなければ、押された選択肢テキスト保存してcallClaude呼出し
                    onPressed: isLoading ? null
                        : () async {
                      await hiveService.saveChoice((choice));
                      await hiveService.DeleteChoices();        //ストレージの方のchoicesの削除
                      await callClaude();
                      //質問の生成に失敗したときのエラーハンドリング用
                      if(question.isNotEmpty){
                        //分析ステージ４以上でリザルト画面へ
                        if (questionCount >= 4){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Result()),
                          );
                        }else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SecondQuestion(question: question,)),
                          );
                        }//trueの時_is..をnullにfalseの時callClaude実行
                      }else{
                        // エラーハンドリング（例：スナックバーでエラーメッセージを表示）
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('質問の生成に失敗しました。もう一度お試しください。')),
                        );
                      }
                    },
                    child: Text(choice),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      )
    );
  }
}