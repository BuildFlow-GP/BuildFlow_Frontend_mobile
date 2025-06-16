import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String searchQuery = '';

  final List<Contact> contacts = [
    Contact(
      id: '1',
      name: 'Alice',
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
      lastMessage: 'Hey there!',
      unreadCount: 2,
      lastMessageTime: DateTime.now().subtract(Duration(minutes: 10)),
    ),
    Contact(
      id: '2',
      name: 'Bob',
      avatarUrl: 'https://i.pravatar.cc/150?img=2',
      lastMessage: 'Did you finish the report?',
      unreadCount: 0,
      lastMessageTime: DateTime.now().subtract(Duration(hours: 3)),
    ),
    Contact(
      id: '3',
      name: 'Charlie',
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      lastMessage: 'Let’s catch up tomorrow.',
      unreadCount: 5,
      lastMessageTime: DateTime.now().subtract(Duration(days: 1)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredContacts =
        contacts
            .where(
              (c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();

    filteredContacts.sort(
      (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Chat List',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              color: AppColors.card,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search ...',
                  prefixIcon: Icon(Icons.search, color: AppColors.accent),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SizedBox(
          width:
              MediaQuery.of(context).size.width > 800
                  ? MediaQuery.of(context).size.width * 0.75
                  : MediaQuery.of(context).size.width,
          child: ListView.builder(
            itemCount: filteredContacts.length,
            itemBuilder: (context, index) {
              final contact = filteredContacts[index];
              return Card(
                color: AppColors.card,
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(contact.avatarUrl),
                        radius: 25,
                      ),
                      if (contact.unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${contact.unreadCount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    contact.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    contact.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(contact: contact),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
