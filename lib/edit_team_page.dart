import 'package:flutter/material.dart';
import 'package:himacheck/auth/auth.dart';
import 'script/firestore_service.dart';
import 'models/status.dart';

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
      appBar: AppBar(
        title: Text('チーム管理'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showCreateTeamDialog(context);
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
                        _showEditTeamDialog(context, team);
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

  void _showCreateTeamDialog(BuildContext context) {
    final _teamNameController = TextEditingController();
    final FirestoreService firestoreService = FirestoreService();
    final user = authService.getCurrentUser();


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
                  firestoreService.createTeam(user!.uid, teamName);
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

  void _showEditTeamDialog(BuildContext context, Team team) {
    final _teamNameController = TextEditingController(text: team.name);
    final FirestoreService firestoreService = FirestoreService();
    final user = authService.getCurrentUser();


    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('チーム編集'),
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
                  firestoreService.updateTeam(user!.uid, team.id, teamName);
                }
                Navigator.of(context).pop();
              },
              child: Text('保存'),
            ),
          ],
        );
      },
    );
  }
}

class TeamDetailsPage extends StatelessWidget {
  final Team team;

  TeamDetailsPage({required this.team});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authService = AuthService();
    final user = authService.getCurrentUser();

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
      ),
      body: StreamBuilder<List<Friend>>(
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
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          _showAddFriendDialog(context, team);
        },
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context, Team team) {
    final firestoreService = FirestoreService();
    final authService = AuthService();
    final user = authService.getCurrentUser();

    if (user == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('友達を追加'),
          content: StreamBuilder<List<Friend>>(
            stream: firestoreService.getUserFriends(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No friends available'));
              }
              final friends = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return ListTile(
                    title: Text(friend.name),
                    onTap: () {
                      firestoreService.addFriendToTeam(user.uid, team.id, friend.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }
}

