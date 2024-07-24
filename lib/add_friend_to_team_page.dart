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
    print('TeamId: ${team.id}');//Teamidが正しく取得できていない
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('友達を追加'),
      ),
      body: StreamBuilder<List<String>>(
        stream: firestoreService.getFriendIds(userId), // 自分の友達リストを取得
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
                    
          final friendIds = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            itemCount: friendIds.length,
            itemBuilder: (context, index) {
              final friendId = friendIds[index];
              print('FriendId: ${friendId}');//確認用
              return FutureBuilder<Friend>(
                future: firestoreService.getFriendById(friendId),
                builder: (context, friendSnapshot) {
                  if (friendSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Loading...'),
                    );
                  }
                  if (friendSnapshot.hasError) {
                    return ListTile(
                      title: Text('Error loading friend'),
                    );
                  }
                  final friend = friendSnapshot.data!;
                      print('Friend ID from FutureBuilder: ${friend.id}');
                      print('Friend Name from FutureBuilder: ${friend.name}');
                  return ListTile(
                    title: Text(friend.name),
                  onTap: () {//userId, team.id, friend.idが空欄でないのが問題となっています。
                        print('Adding friend to team...');
                        print('User ID: $userId');
                        print('Team ID: ${team.id}');
                        print('Friend ID: ${friend.id}');
                    firestoreService.addFriendToTeam(userId, team.id, friendId).then(
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
          );
        },
      ),
    );
  }
}
