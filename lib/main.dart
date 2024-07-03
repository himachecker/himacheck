import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:himacheck/edit_status_page.dart';
import 'package:himacheck/auth.dart';
import 'package:himacheck/timeago.dart';
import 'firebase_options.dart';
import 'status.dart';
import 'firestore_service.dart';
import 'package:timeago/timeago.dart' as timeAgo;


void main() async {
  // Firebaseの初期化を待機
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
      // アプリ名
      title: 'StatusApp',
      theme: ThemeData(
        // テーマカラー
        primarySwatch: Colors.blue,
      ),
      // ログイン画面を表示
      home: MyAuthPage(),
    );
  }
}

// home画面用Widget
class HomePage extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ホーム'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () async {
              // ログイン画面に遷移＋チャット画面を破棄
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) {
                  return MyAuthPage();
                }),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          // 新しいステータスを追加する場合、空の引数を渡す
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              return EditStatusPage(
                documentId: '',
                currentMessage: '',
                currentStatus: true,
                currentname: '',
                currenttimestamp: DateTime.now()
              );
            }),
          );
        },
      ),
      body: StreamBuilder<List<Status>>(
        stream: firestoreService.getStatuses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No statuses available'));
          }
          final statuses = snapshot.data!;
          print('Fetched statuses: $statuses'); // デバッグログ
          return ListView.builder(
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              final status = statuses[index];
              return ListTile(
                title: Text(status.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(status.message),
                    Text(createTimeAgoString(status.timestamp)),
                    Switch(
                      value: status.isActive,
                      onChanged: (value) async {
                        try {
                          await firestoreService.updateStatus(status.id, value, status.message, status.name, status.timestamp);
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
          );
        },
      ),
    );
  }
}
