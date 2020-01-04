import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _getUser(context);
    return Scaffold(
      body: Center(
        child: const Text("かしかりメモ"),
      )
    );
  }

  void _getUser(BuildContext context) async {
    try {
      final firebaseUser = await FirebaseAuth.instance.currentUser();
      if (firebaseUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      Navigator.pushReplacementNamed(context, "/list");
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: "Firebaseとの接続に失敗しました。");
    }
  }
}