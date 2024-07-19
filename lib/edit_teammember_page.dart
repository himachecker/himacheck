import 'package:flutter/material.dart';
import 'package:himacheck/auth/auth.dart';
import 'script/firestore_service.dart';
import 'models/status.dart';

class EditTeamMembersPage extends StatelessWidget {
  final Team team;

  EditTeamMembersPage({required this.team});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authService = AuthService();
    final user = authService.getCurrentUser();

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('メンバー編集'),
        ),
        body: Center(child: Text('ログインしていません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('メンバー編集: ${team.name}'),
      ),
      body: StreamBuilder<List<Friend>>(
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
          content: FutureBuilder<List<Friend>>(
            future: firestoreService.getUserFriends(user.uid),
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
              return SizedBox(
                height: 200.0, // 固定高さを設定
                child: ListView.builder(
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
                ),
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
