import 'package:flutter/material.dart';
import 'models/status.dart';
import 'script/firestore_service.dart';
import 'auth/auth.dart';

class AddFriendToTeamPage extends StatelessWidget {
  final FirestoreService firestoreService;
  final AuthService authService = AuthService();

  final String userId;
  final Team team;

  AddFriendToTeamPage({required this.firestoreService, required this.userId, required this.team})
  {//erorrチェック
    print('UserId: $userId');
    print('TeamId: ${team.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('友達を追加'),
      ),
      body: StreamBuilder<List<Friend>>(
        stream: firestoreService.getUserFriends(userId), // 自分の友達リストを取得
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
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return ListTile(
                title: Text(friend.name),
                onTap: () {//userId, team.id, friend.idが空欄でないのが問題となっています。
                  firestoreService.addFriendToTeam(userId, team.id, friend.id).then(
                    (_) {
                      Navigator.of(context).pop(); // チーム追加後にページを戻す
                    },
                  ).catchError((error) {
                    print('Failed to add friend to team: $error');
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
