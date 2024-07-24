// edit_team_page.dart
import 'package:flutter/material.dart';
import 'models/status.dart';
import 'script/firestore_service.dart';

class EditTeamPage extends StatelessWidget {
  final FirestoreService firestoreService;
  final String userId;
  final Team team;

  EditTeamPage({required this.firestoreService, required this.userId, required this.team});

  @override
  Widget build(BuildContext context) {
    final _teamNameController = TextEditingController(text: team.name);

    return Scaffold(
      appBar: AppBar(
        title: Text('チーム編集'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _teamNameController,
              decoration: InputDecoration(hintText: 'チーム名'),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                      firestoreService.updateTeam(userId, team.id, teamName);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
