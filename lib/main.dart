import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:himacheck/edit_status_page.dart';
import 'package:himacheck/auth/auth.dart';
import 'package:himacheck/script/timeago.dart';
import 'package:himacheck/team_management_page.dart';
import 'script/firebase_options.dart';
import 'models/status.dart';
import 'script/firestore_service.dart';
import 'package:himacheck/add_friend_page.dart';
import 'package:timeago/timeago.dart' as timeAgo;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  timeAgo.setLocaleMessages("ja", timeAgo.JaMessages());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ヒマチェッカー',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.grey), // ラベルの色を灰色に設定
          hintStyle: TextStyle(color: Colors.grey),  // ヒントテキストの色も灰色に設定
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue), // フォーカス時の下線の色
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // 通常時の下線の色
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red), // エラー時の下線の色
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red), // フォーカス時のエラー下線の色
          ),    
        ),
                elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 51, 180, 240), // ElevatedButtonの背景色
            foregroundColor: Colors.white, // ElevatedButtonのテキスト色
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blue, // カーソルの色を青に設定
        ),
      ),
      home: MyAuthPage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = authService.getCurrentUser();

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('ホーム'),
        backgroundColor: const Color.fromARGB(255, 51, 180, 240),
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () async {
              await authService.signOut();
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) {
                  return MyAuthPage();
                }),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.group),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => TeamManagementPage(),
              ));
            },
          ),
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AddFriendPage(),
              ));
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 960, // 横幅を960pxに設定
          padding: EdgeInsets.all(16.0), // 追加のパディング
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 左揃えにする
            children: [
              StreamBuilder<Status?>(
                stream: firestoreService.getUserStatus(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Center(child: Text('No status available'));
                  }
                  final status = snapshot.data!;
                  return ListTile(
                    title: Text(status.name),
                    subtitle: Text(status.message),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(createTimeAgoString(status.timestamp)),
                        Switch(
                          value: status.isActive,
                          activeColor: Colors.blue,
                          onChanged: (value) async {
                            try {
                              await firestoreService.updateStatus(
                                user.uid,
                                value,
                                status.message,
                                status.name,
                                status.timestamp,
                              );
                            } catch (e) {
                              print('Error updating status: $e');
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => EditStatusPage(
                                documentId: status.id,
                                currentMessage: status.message,
                                currentStatus: status.isActive,
                                currentname: status.name,
                                currenttimestamp: status.timestamp,
                              ),
                            ));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 16.0), // アイテム間にスペースを追加
              Expanded(
                child: StreamBuilder<List<Status>>(
                  stream: firestoreService.getFriendsStatuses(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No friends statuses available'));
                    }
                    final statuses = snapshot.data!;
                    return ListView.builder(
                      itemCount: statuses.length,
                      itemBuilder: (context, index) {
                        final status = statuses[index];
                        return ListTile(
                          title: Text(status.name),
                          subtitle: Text(status.message),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(createTimeAgoString(status.timestamp)),
                              Icon(
                                status.isActive ? Icons.check_circle : Icons.cancel,
                                color: status.isActive ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
