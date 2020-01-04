import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:share/share.dart';

class InputForm extends StatefulWidget {
  InputForm(this.document);

  final DocumentSnapshot document;

  @override
  _MyInputFormState createState() => _MyInputFormState();
}

class _FormData {
  String borrowOrLend = "borrow";
  String user;
  String stuff;
  DateTime date = DateTime.now();
}

class _MyInputFormState extends State<InputForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _FormData _data = _FormData();
  final _dateFormatter = DateFormat("yyyy/MM/dd");

  Future<DateTime> _selectTime(BuildContext context) {
    return showDatePicker(
        context: context,
        initialDate: _data.date,
        firstDate: DateTime(_data.date.year - 2),
        lastDate: DateTime(_data.date.year + 2));
  }

  void showConfirmDelete({Function onClickOK}) {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
              title: const Text("確認"),
              content: const Text("削除します。よろしいですか？"),
              actions: <Widget>[
                FlatButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(context)),
                FlatButton(
                    child: const Text("OK"),
                    onPressed: () {
                      onClickOK();
                      Navigator.pop(context);
                    })
              ]);
        });
  }

  void _setBorrowOrLend(String value) {
    setState(() {
      _data.borrowOrLend = value;
    });
  }

  Future<FirebaseUser> _getUser() async {
    return await FirebaseAuth.instance.currentUser();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUserFuture = _getUser();

    return FutureBuilder<FirebaseUser>(
        future: firebaseUserFuture,
        builder: (BuildContext context, AsyncSnapshot<FirebaseUser> snapshot) {
          final firebaseUser = snapshot.data;
          DocumentReference _mainReference;
          _mainReference = Firestore.instance
              .collection('users')
              .document(firebaseUser.uid)
              .collection('transaction')
              .document();
          bool canDelete = false;
          if (widget.document != null) {
            // editの場合
            if (_data.user == null && _data.stuff == null) {
              _data.borrowOrLend = widget.document['borrowOrLend'];
              _data.user = widget.document['user'];
              _data.stuff = widget.document['stuff'];
              _data.date = widget.document['date'].toDate();
            }

            canDelete = true;

            _mainReference = Firestore.instance
                .collection('users')
                .document(firebaseUser.uid)
                .collection('transaction')
                .document(widget.document.documentID);
          }

          return Scaffold(
              appBar: AppBar(title: const Text("かしかり入力"), actions: <Widget>[
                IconButton(
                    icon: Icon(Icons.save),
                    onPressed: () {
                      print("保存ボタン押した！");
                      if (_formKey.currentState.validate()) {
                        _formKey.currentState.save();
                        _mainReference.setData({
                          'borrowOrLend': _data.borrowOrLend,
                          'user': _data.user,
                          'stuff': _data.stuff,
                          'date': _data.date,
                        });
                        Navigator.pop(context);
                      }
                    }),
                IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      print("削除ボタン押した！");
                      if (canDelete) {
                        showConfirmDelete(onClickOK: () {
                          _mainReference.delete();
                          Navigator.pop(context);
                        });
                      }
                    }),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      _formKey.currentState.save();
                      Share.share(
                        "【${_data.borrowOrLend == 'lend' ? '貸' : '借'}】${_data.stuff}\n期限：${_dateFormatter.format(_data.date)}\n相手：${_data.user}\n#かしかりメモ"
                      );
                    }
                  },
                )
              ]),
              body: SafeArea(
                  child: Form(
                      key: _formKey,
                      child: ListView(
                          padding: const EdgeInsets.all(20.0),
                          children: <Widget>[
                            RadioListTile(
                                value: "borrow",
                                groupValue: _data.borrowOrLend,
                                title: const Text("借りた"),
                                onChanged: (String value) {
                                  print("${value}をタッチしました");
                                  _setBorrowOrLend(value);
                                }),
                            RadioListTile(
                                value: "lend",
                                groupValue: _data.borrowOrLend,
                                title: const Text("貸した"),
                                onChanged: (String value) {
                                  print("${value}をタッチしました");
                                  _setBorrowOrLend(value);
                                }),
                            TextFormField(
                                decoration: const InputDecoration(
                                  icon: Icon(Icons.person),
                                  hintText: "相手の名前",
                                  labelText: "Name",
                                ),
                                onSaved: (String value) {
                                  _data.user = value;
                                },
                                validator: (String value) {
                                  if (value.isEmpty) {
                                    return "名前は必須入力項目です。";
                                  }
                                  return null;
                                },
                                initialValue: _data.user),
                            TextFormField(
                                decoration: const InputDecoration(
                                  icon: Icon(Icons.business_center),
                                  hintText: "借りたもの、貸したもの",
                                  labelText: "Stuff",
                                ),
                                onSaved: (String value) {
                                  _data.stuff = value;
                                },
                                validator: (String value) {
                                  if (value.isEmpty) {
                                    return "借りたもの、貸したものは必須入力項目です。";
                                  }
                                  return null;
                                },
                                initialValue: _data.stuff),
                            Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text(
                                    "締め切り日：${_dateFormatter.format(_data.date)}")),
                            RaisedButton(
                                child: const Text("締め切り日変更"),
                                onPressed: () async {
                                  print("締め切り日変更をタッチしました");
                                  final selectedTime =
                                      await _selectTime(context);
                                  if (selectedTime != null &&
                                      selectedTime != _data.date) {
                                    setState(() {
                                      _data.date = selectedTime;
                                    });
                                  }
                                })
                          ]))));
        });
  }
}
