import 'package:flutter/material.dart';
import 'firestore_service.dart';

class EditStatusPage extends StatefulWidget {
  final String documentId;
  final String currentMessage;
  final bool currentStatus;

  EditStatusPage({
    required this.documentId,
    required this.currentMessage,
    required this.currentStatus,
  });

  @override
  _EditStatusPageState createState() => _EditStatusPageState();
}

class _EditStatusPageState extends State<EditStatusPage> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController _messageController = TextEditingController();

  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _messageController.text = widget.currentMessage;
    _isActive = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _messageController,
              decoration: InputDecoration(labelText: 'Message'),
            ),
            SwitchListTile(
              title: Text('Active'),
              value: _isActive,
              onChanged: (bool value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: () async {
                if (widget.documentId.isEmpty) {
                  // 新しいドキュメントを作成
                  await firestoreService.addStatus(
                    _messageController.text,
                    _isActive,
                  );
                } else {
                  // 既存のドキュメントを更新
                  await firestoreService.updateStatus(
                    widget.documentId,
                    _isActive,
                    _messageController.text,
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
