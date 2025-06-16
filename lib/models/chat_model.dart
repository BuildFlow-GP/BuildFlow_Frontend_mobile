class Contact {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final int unreadCount;
  final DateTime lastMessageTime;

  Contact({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.unreadCount,
    required this.lastMessageTime,
  });
}
