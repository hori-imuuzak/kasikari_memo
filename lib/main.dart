import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:kasikari_memo/input.dart';
import 'package:kasikari_memo/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

//  final Firestore firestore = Firestore();
//  await firestore.settings(timestampsInSnapshotsEnabled: true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'かしかりメモ',
        routes: <String, WidgetBuilder>{
          '/': (_) => Splash(),
          '/list': (_) => List()
        }
    );
  }
}

class List extends StatefulWidget {
  @override
  _MyList createState() => _MyList();
}

class _MyList extends State<List> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseUser>(
      future: FirebaseAuth.instance.currentUser(),
      builder: (BuildContext context, AsyncSnapshot<FirebaseUser> snapshot) {
        final firebaseUser = snapshot.data;

        return Scaffold(
            appBar: AppBar(
                title: const Text("リスト画面"),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.exit_to_app),
                    onPressed: () {
                      print("Login");
                      showBasicDialog(context);
                    },
                  )
                ]
            ),
            body: Padding(
                padding: const EdgeInsets.all(8.0),
                child: StreamBuilder<QuerySnapshot>(
                    stream:
                    Firestore.instance
                        .collection('users')
                        .document(firebaseUser.uid)
                        .collection('transaction')
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) return const Text('Loading...');
                      return ListView.builder(
                          itemCount: snapshot.data.documents.length,
                          padding: const EdgeInsets.only(top: 10),
                          itemBuilder: (context, index) => _buildListItem(
                              context, snapshot.data.documents[index]));
                    })),
            floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () {
                  print("新規作成ボタンを押した！");
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: const RouteSettings(name: "/new"),
                          builder: (BuildContext context) => InputForm(null)
                      )
                  );
                }));
      }
    );
  }

  void showBasicDialog(BuildContext context) async {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    String email, password;
    final firebaseUser = await FirebaseAuth.instance.currentUser();
    if (firebaseUser != null && firebaseUser.isAnonymous) {
      showDialog(
        context: context,
        builder: (BuildContext) {
          return AlertDialog(
            title: const Text("ログイン/登録ダイアログ"),
            content: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.mail),
                      labelText: 'Email',
                    ),
                    onSaved: (String value) {
                      email = value;
                    },
                    validator: (String value) {
                      if (value.isEmpty) {
                        return "Emailは入力必須項目です。";
                      }
                      return null;
                    }
                  ),
                  TextFormField(
                      decoration: const InputDecoration(
                        icon: const Icon(Icons.vpn_key),
                        labelText: 'Password',
                      ),
                      onSaved: (String value) {
                        password = value;
                      },
                      validator: (String value) {
                        if (value.isEmpty) {
                          return "Passwordは入力必須項目です。";
                        }
                        if (value.length < 6) {
                          return "Passwordは6桁以上入力してください。";
                        }
                        return null;
                      }
                  )
                ]
              )
            ),
            actions: <Widget>[
              FlatButton(
                child: const Text("キャンセル"),
                onPressed: () {
                  Navigator.pop(context);
                }
              ),
              FlatButton(
                child: const Text("登録"),
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();
                    _createUser(context, email, password);
                  }
                }
              ),
              FlatButton(
                child: const Text("ログイン"),
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();
                    _signIn(context, email, password);
                  }
                }
              )
            ]
          );
        }
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("確認"),
            content: Text("${firebaseUser.email}でログインしています。"),
            actions: <Widget>[
              FlatButton(
                child: const Text("キャンセル"),
                onPressed: () => Navigator.pop(context)
              ),
              FlatButton(
                child: const Text("ログアウト"),
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    "/",
                    (_) => false
                  );
                }
              )
            ]
          );
        }
      );
    }
  }

  void _createUser(BuildContext context, String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
    } catch (e) {
      Fluttertoast.showToast(msg: "登録に失敗しました。");
    }
  }

  void _signIn(BuildContext context, String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
    } catch (e) {
      Fluttertoast.showToast(msg: "ログインに失敗しました。");
    }
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    final dateFormatter = DateFormat("yyyy/MM/dd");
    return Card(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      ListTile(
          leading: const Icon(Icons.android),
          title: Text("【" +
              (document['borrowOrLend'] == "lend" ? "貸" : "借") +
              "】" +
              document['stuff']),
          subtitle: Text("期限：" +
              dateFormatter.format(document['date'].toDate()) +
              "\n相手：" +
              document['user'])),
      ButtonBarTheme(
          data: ButtonBarThemeData(),
          child: ButtonBar(
            children: <Widget>[
              FlatButton(
                child: const Text("編集"),
                onPressed: () {
                  print("編集ボタンを押した！");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: "/edit"),
                      builder: (BuildContext context) => InputForm(document)
                    )
                  );
                },
              )
            ],
          ))
    ]));
  }
}
