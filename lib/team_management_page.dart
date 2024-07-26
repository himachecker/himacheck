// team_management_page.dart
import 'package:flutter/material.dart';
import 'package:himacheck/team_detail_page.dart';
import 'edit_team_page.dart'; // 新しいファイルをインポート
import 'models/status.dart';
import 'script/firestore_service.dart';
import 'auth/auth.dart';

class TeamManagementPage extends StatefulWidget {
  @override
  _TeamManagementPageState createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
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
        title: Text('チーム管理'),
        backgroundColor: const Color.fromARGB(255, 51, 180, 240), // バナーの背景色を水色に設定
        foregroundColor: Colors.white, // アイコンとテキストの色を白に設定
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showCreateTeamPage(context, user.uid);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Team>>(
        stream: firestoreService.getUserTeams(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No teams available'));
          }
          final teams = snapshot.data!;
          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return ListTile(
                title: Text(team.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => EditTeamPage(
                            firestoreService: firestoreService,
                            userId: user.uid,
                            team: team,
                          ),
                        ));
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        firestoreService.deleteTeam(user.uid, team.id);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => TeamDetailsPage(team: team),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateTeamPage(BuildContext context, String userId) {
    final _teamNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('新規チーム作成'),
          content: TextField(
            controller: _teamNameController,
            decoration: InputDecoration(hintText: 'チーム名'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                final teamName = _teamNameController.text.trim();
                if (teamName.isNotEmpty) {
                  firestoreService.createTeam(userId, teamName);
                }
                Navigator.of(context).pop();
              },
              child: Text('作成'),
            ),
          ],
        );
      },
    );
  }
}
