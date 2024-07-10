// auth.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart';
import 'main.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> registerUser(String email, String password, String name) async {
    final UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final User user = result.user!;
    final FirestoreService firestoreService = FirestoreService();

    // ステータスを自動生成
    await firestoreService.addStatus(
      "はじめまして",
      true,
      name,
      DateTime.now(),
      user.uid,
    );
  }
}

class MyAuthPage extends StatefulWidget {
  @override
  _MyAuthPageState createState() => _MyAuthPageState();
}

class _MyAuthPageState extends State<MyAuthPage> {
  String newUserEmail = "";
  String newUserName = ""; // 追加: ユーザー名
  String newUserPassword = "";
  String loginUserEmail = "";
  String loginUserPassword = "";
  String infoText = "";

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: "ユーザー名"), // 追加: ユーザー名入力フィールド
                onChanged: (String value) {
                  setState(() {
                    newUserName = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "メールアドレス"),
                onChanged: (String value) {
                  setState(() {
                    newUserEmail = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "パスワード（６文字以上）"),
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    newUserPassword = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await authService.registerUser(newUserEmail, newUserPassword, newUserName);
                    final User? user = authService.getCurrentUser();
                    setState(() {
                      infoText = "登録OK：${user?.email}";
                    });
                  } catch (e) {
                    setState(() {
                      infoText = "登録NG：${e.toString()}";
                    });
                  }
                },
                child: Text("ユーザー登録"),
              ),
              const SizedBox(height: 32),
              TextFormField(
                decoration: InputDecoration(labelText: "メールアドレス"),
                onChanged: (String value) {
                  setState(() {
                    loginUserEmail = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "パスワード"),
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    loginUserPassword = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final UserCredential result = await authService._auth.signInWithEmailAndPassword(
                      email: loginUserEmail,
                      password: loginUserPassword,
                    );
                    final User user = result.user!;
                    setState(() {
                      infoText = "ログインOK：${user.email}";
                    });
                    await Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) {
                        return HomePage();
                      }),
                    );
                  } catch (e) {
                    setState(() {
                      infoText = "ログインNG：${e.toString()}";
                    });
                  }
                },
                child: Text("ログイン"),
              ),
              const SizedBox(height: 8),
              Text(infoText),
            ],
          ),
        ),
      ),
    );
  }
}
