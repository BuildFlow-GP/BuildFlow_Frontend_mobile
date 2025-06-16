import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final Contact contact;

  const ChatScreen({super.key, required this.contact});

  @override
  // ignore: library_private_types_in_public_api
  _ChatScreenState createState() => _ChatScreenState();
}

class Message {
  final String username;
  final String text;
  final bool isSentByMe;
  final DateTime timestamp;

  Message({
    required this.username,
    required this.text,
    required this.isSentByMe,
    required this.timestamp,
  });
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<Message> messages = [
    Message(
      username: 'Alice',
      text: 'Hello! 😊',
      isSentByMe: false,
      timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    ),
    Message(
      username: 'Me',
      text: 'Hi Alice, how are you?',
      isSentByMe: true,
      timestamp: DateTime.now().subtract(Duration(minutes: 4)),
    ),
    Message(
      username: 'Alice',
      text: 'I am good, thanks! 👍',
      isSentByMe: false,
      timestamp: DateTime.now().subtract(Duration(minutes: 3)),
    ),
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  bool showEmojiPicker = false;
  bool isSendButtonVisible = false;

  @override
  void initState() {
    super.initState();

    // مراقبة النص لتحديث ظهور زر الإرسال
    _controller.addListener(() {
      setState(() {
        isSendButtonVisible = _controller.text.trim().isNotEmpty;
      });
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      showEmojiPicker = !showEmojiPicker;
      if (showEmojiPicker) {
        focusNode.unfocus();
      } else {
        focusNode.requestFocus();
      }
    });
  }

  void _onEmojiSelected(Emoji emoji) {
    _controller
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = Message(
      username: 'Me',
      text: text,
      isSentByMe: true,
      timestamp: DateTime.now(),
    );

    _controller.clear();
    setState(() {
      showEmojiPicker = false;
      isSendButtonVisible = false;
      messages.insert(0, message); // نضيف الرسالة في بداية القائمة
      _listKey.currentState?.insertItem(0); // تشغيل حركة الإضافة
    });

    // تمرير سلس للأسفل (لأحدث رسالة)
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessageItem(
    BuildContext context,
    int index,
    Animation<double> animation,
  ) {
    final message = messages[index];

    final alignment =
        message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft;
    final cardColor = message.isSentByMe ? AppColors.accent : AppColors.card;
    final textColor = message.isSentByMe ? AppColors.card : AppColors.accent;
    final borderRadius = BorderRadius.circular(16);

    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: 0.0,
      child: Align(
        alignment: alignment,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Column(
            crossAxisAlignment:
                message.isSentByMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
            children: [
              Text(
                message.username,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Card(
                elevation: 2,
                color: cardColor,
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Text(
                    message.text,
                    style: TextStyle(color: textColor, fontSize: 18),
                    textAlign:
                        message.isSentByMe ? TextAlign.right : TextAlign.left,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                DateFormat('hh:mm a').format(message.timestamp),
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact.name),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: screenWidth * 0.75,
          height: screenHeight * 0.75,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: AnimatedList(
                  key: _listKey,
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(8),
                  initialItemCount: messages.length,
                  itemBuilder: _buildMessageItem,
                ),
              ),
              Divider(height: 1),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.emoji_emotions_outlined,
                        color: AppColors.accent,
                      ),
                      onPressed: _toggleEmojiPicker,
                    ),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 48,
                          maxHeight: 120,
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: focusNode,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                          ),
                          textInputAction: TextInputAction.newline,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      transitionBuilder:
                          (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                      child:
                          isSendButtonVisible
                              ? IconButton(
                                key: ValueKey('sendButton'),
                                icon: Icon(Icons.send, color: AppColors.accent),
                                onPressed: _sendMessage,
                              )
                              : SizedBox(
                                key: ValueKey('emptySpace'),
                                width: 48,
                                height: 48,
                              ),
                    ),
                  ],
                ),
              ),
              if (showEmojiPicker)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      _onEmojiSelected(emoji);
                    },
                    config: Config(
                      // columns: 7,
                      // emojiSizeMax: 32,
                      // verticalSpacing: 0,
                      // horizontalSpacing: 0,
                      // initCategory: Category.SMILEYS,
                      // bgColor: Colors.white,
                      // indicatorColor: AppColors.primary,
                      // iconColor: Colors.grey,
                      // iconColorSelected: AppColors.primary,
                      // backspaceColor: AppColors.primary,
                      // buttonMode: ButtonMode.MATERIAL,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
