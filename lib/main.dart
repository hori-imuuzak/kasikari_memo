import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kasikari_memo/input.dart';
import 'package:kasikari_memo/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Firestore firestore = Firestore();
  await firestore.settings(timestampsInSnapshotsEnabled: true);

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
    return Scaffold(
        appBar: AppBar(
          title: const Text("リスト画面"),
        ),
        body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: StreamBuilder<QuerySnapshot>(
                stream:
                    Firestore.instance.collection('kasikari-memo').snapshots(),
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
