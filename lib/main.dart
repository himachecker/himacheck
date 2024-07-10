import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:himacheck/edit_status_page.dart';
import 'package:himacheck/auth.dart';
import 'package:himacheck/timeago.dart';
import 'firebase_options.dart';
import 'status.dart';
import 'firestore_service.dart';
import 'package:himacheck/add_friend_page.dart';
import 'package:timeago/timeago.dart' as timeAgo;


// home画面用Widget
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
      title: 'StatusApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyAuthPage(),
    );
  }
}

// HomePageクラスの修正
// home画面用Widget
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
      appBar: AppBar(
        title: Text('ホーム'),
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
            icon: Icon(Icons.person_add),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AddFriendPage(),
              ));
            },
          ),
        ],
      ),
      body: Column(
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
                      onChanged: (value) async {
                        try {
                          await firestoreService.updateStatus(
                            user.uid,
                            value,
                            status.message,
                            status.name,
                            status.timestamp
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
                      trailing: Text(createTimeAgoString(status.timestamp)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}