import 'package:timeago/timeago.dart' as timeAgo;

String createTimeAgoString(DateTime postDateTime) {
  final now = DateTime.now();
  final difference = now.difference(postDateTime);
  return timeAgo.format(now.subtract(difference), locale: "ja");
}

//createTimeAgoString(比較日時)で何日前表記の実装