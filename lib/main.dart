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
            backgroundColor: Color.fromARGB(255, 51, 180, 240), // アクティブな時の背景色
            foregroundColor: Colors.white, // アクティブな時の文字色
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 51, 180, 240), 
            foregroundColor: Colors.white,// TextButtonの文字色
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent, // OutlinedButtonの背景色（透明にする）
            foregroundColor: Color.fromARGB(255, 51, 180, 240), // OutlinedButtonの文字色
            side: BorderSide(color: Color.fromARGB(255, 51, 180, 240)), // OutlinedButtonのボーダー色
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blue, // カーソルの色を青に設定
        ),
        scaffoldBackgroundColor: Colors.white, // 背景色を白に設定
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(255, 51, 180, 240), // AppBarの背景色を水色に設定
          foregroundColor: Colors.white, // AppBarのアイコンとテキストの色を白に設定
        ),
         tabBarTheme: TabBarTheme(
          labelColor: Colors.white, // タブバー上の選択されたタブの文字色
          unselectedLabelColor: Colors.white70, // タブバー上の未選択のタブの文字色
          indicator: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white, // タブバーのアンダーバーの色
                width: 2.0, // アンダーバーの太さ
              ),
            ),
          ),
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
        body: Center(child: Text('ユーザーがログインしていません')),
      );
    }

    return StreamBuilder<List<Team>>(
      stream: firestoreService.getUserTeams(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('エラー: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('チームが見つかりません'));
        }
        final teams = snapshot.data!;
        return DefaultTabController(
          length: teams.length + 1, // タブの数を増やす
          child: Scaffold(
            backgroundColor: Colors.white,
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
              bottom: TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: '全体'),
                  ...teams.map((team) => Tab(text: team.name)).toList(),
                ],
              ),
            ),
            body: Center(
              child: Container(
                width: 960, // 横幅を960pxに設定
                padding: EdgeInsets.all(16.0), // 追加のパディング
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 自身のステータス表示
                    StreamBuilder<Status?>(
                      stream: firestoreService.getUserStatus(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('エラー: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Center(child: Text('ステータスが利用できません'));
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
                                    print('ステータスの更新中にエラーが発生しました: $e');
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
                      child: TabBarView(
                        children: [
                          AllFriendsTab(),
                          ...teams.map((team) => TeamMembersTab(team: team)).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AllFriendsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authService = AuthService();
    final user = authService.getCurrentUser();

    if (user == null) {
      return Center(child: Text('ユーザーがログインしていません'));
    }

    return StreamBuilder<List<Status>>(
      stream: firestoreService.getFriendsStatuses(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('エラー: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('友達のステータスが利用できません'));
        }
        final statuses = snapshot.data!;

        // アクティブなメンバーを上部に表示
        statuses.sort((a, b) {
          if (a.isActive && !b.isActive) return -1;
          if (!a.isActive && b.isActive) return 1;
          return 0;
        });

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
    );
  }
}

class TeamMembersTab extends StatelessWidget {
  final Team team;

  TeamMembersTab({required this.team});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authService = AuthService();
    final user = authService.getCurrentUser();

    if (user == null) {
      return Center(child: Text('ユーザーがログインしていません'));
    }

    return StreamBuilder<List<Friend>>(
      stream: firestoreService.getTeamMembers(user.uid, team.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('エラー: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('このチームにはメンバーがいません'));
        }
        final friends = snapshot.data!;

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return StreamBuilder<Status?>(
              stream: firestoreService.getUserStatus(friend.id),
              builder: (context, statusSnapshot) {
                if (statusSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: Text(friend.name),
                    subtitle: Text('ステータスを読み込み中...'),
                    trailing: CircularProgressIndicator(),
                  );
                }
                if (statusSnapshot.hasError) {
                  return ListTile(
                    title: Text(friend.name),
                    subtitle: Text('ステータスの読み込み中にエラーが発生しました'),
                  );
                }
                if (!statusSnapshot.hasData || statusSnapshot.data == null) {
                  return ListTile(
                    title: Text(friend.name),
                    subtitle: Text('ステータスが利用できません'),
                  );
                }
                final status = statusSnapshot.data!;
                return ListTile(
                  title: Text(friend.name),
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
        );
      },
    );
  }
}
