// add_friend_page.dart

import 'package:flutter/material.dart';
import 'script/firestore_service.dart';
import 'auth/auth.dart';

class AddFriendPage extends StatefulWidget {
  @override
  _AddFriendPageState createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final FirestoreService firestoreService = FirestoreService();
  final AuthService authService = AuthService();
  final TextEditingController friendIdController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    final user = authService.getCurrentUser();

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('友達追加'),
        backgroundColor: const Color.fromARGB(255, 51, 180, 240), // バナーの背景色を水色に設定
        foregroundColor: Colors.white, // アイコンとテキストの色を白に設定
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: friendIdController,
              decoration: InputDecoration(labelText: '友達のUID'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await firestoreService.addFriend(user.uid, friendIdController.text);
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Error adding friend: $e');
                }
              },
              child: Text('追加'),
            ),
          ],
        ),
      ),
    );
  }
}
