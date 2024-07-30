// edit_status_page.dart

import 'package:flutter/material.dart';
import 'script/firestore_service.dart';
import 'auth/auth.dart';

class EditStatusPage extends StatefulWidget {
  final String documentId;
  final String currentMessage;
  final bool currentStatus;
  final String currentname;
  final DateTime currenttimestamp;

  EditStatusPage({
    required this.documentId,
    required this.currentMessage,
    required this.currentStatus,
    required this.currentname,
    required this.currenttimestamp,
  });

  @override
  _EditStatusPageState createState() => _EditStatusPageState();
}

class _EditStatusPageState extends State<EditStatusPage> {
  final FirestoreService firestoreService = FirestoreService();
  final AuthService authService = AuthService();

  late TextEditingController messageController;
  late bool isActive;
  late DateTime timestamp;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController(text: widget.currentMessage);
    isActive = widget.currentStatus;
    timestamp = widget.currenttimestamp;
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    try {
      await firestoreService.updateStatus(
        authService.getCurrentUser()!.uid,
        isActive,
        messageController.text,
        widget.currentname,
        timestamp,
      );
      Navigator.of(context).pop(); // 戻る
    } catch (e) {
      // エラーダイアログを表示
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('エラー'),
          content: Text('ステータスの更新中にエラーが発生しました: $e'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

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
        title: Text('ステータスの編集'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: messageController,
              decoration: InputDecoration(labelText: 'メッセージ'),
            ),
            SwitchListTile(
              title: Text('アクティブ'),
              value: isActive,
              onChanged: (value) {
                setState(() {
                  isActive = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateStatus,
              child: Text('更新'),
            ),
          ],
        ),
      ),
    );
  }
}
