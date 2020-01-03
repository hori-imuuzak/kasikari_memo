import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Splash extends StatelessWidget {
  FirebaseUser firebaseUser;

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
      firebaseUser = await FirebaseAuth.instance.currentUser();
      if (firebaseUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        firebaseUser = await FirebaseAuth.instance.currentUser();
      }

      Navigator.pushReplacementNamed(context, "/list");
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: "Firebaseとの接続に失敗しました。");
    }
  }
}