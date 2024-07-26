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

    return StreamBuilder<List<Team>>(
      stream: firestoreService.getUserTeams(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No teams found'));
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
            body: Column(
              children: [
                // 自身のステータス表示
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
      return Center(child: Text('User not logged in'));
    }

    return StreamBuilder<List<Status>>(
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
      return Center(child: Text('User not logged in'));
    }

    return StreamBuilder<List<Friend>>(
      stream: firestoreService.getTeamMembers(user.uid, team.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No members in this team'));
        }
        final friends = snapshot.data!;
 

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return ListTile(
              title: Text(friend.name),
              trailing: IconButton(
                icon: Icon(Icons.remove_circle),
                onPressed: () {
                  firestoreService.removeFriendFromTeam(user.uid, team.id, friend.id);
                },
              ),
            );
          },
        );
      },
    );
  }
}