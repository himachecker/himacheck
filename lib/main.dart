import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:himacheck/edit_status_page.dart';
import 'package:himacheck/auth.dart';
import 'firebase_options.dart';
import 'status.dart';
import 'firestore_service.dart';

void main() async {
  // Firebaseの初期化を待機
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No statuses available'));
          }
          final statuses = snapshot.data!;
          return ListView.builder(
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              final status = statuses[index];
              return ListTile(
                title: Text(status.message),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: status.isActive,
                      onChanged: (value) async {
                        try {
                          await firestoreService.updateStatus(status.id, value, status.message);
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
