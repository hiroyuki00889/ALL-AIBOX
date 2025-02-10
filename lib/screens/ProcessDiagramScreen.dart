import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test_flutter4/Hive.dart';
import 'Result.dart';

/**　
 *
 */
class ProcessDiagramScreen extends StatefulWidget {
  @override
  _ProcessDiagramScreen createState() => _ProcessDiagramScreen();
}

/**　
 *
 */
class _ProcessDiagramScreen extends State<ProcessDiagramScreen> {


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