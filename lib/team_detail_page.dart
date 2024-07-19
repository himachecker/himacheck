// team_details_page.dart
import 'package:flutter/material.dart';
import 'add_friend_to_team_page.dart'; // 新しいファイルをインポート
import 'models/status.dart';
import 'script/firestore_service.dart';
import 'auth/auth.dart';

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
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AddFriendToTeamPage(
              firestoreService: firestoreService,
              userId: user.uid,
              team: team,
            ),
          ));
        },
      ),
    );
  }
}
