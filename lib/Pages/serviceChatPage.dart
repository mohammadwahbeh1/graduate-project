import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ServiceChatPage extends StatefulWidget {
  final String receiverId;
  const ServiceChatPage({Key? key, required this.receiverId}) : super(key: key);

  @override
  _ServiceChatPageState createState() => _ServiceChatPageState();
}

class _ServiceChatPageState extends State<ServiceChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late WebSocketChannel _channel;
  static const storage = FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();
  String? currentUserId;
  bool _isEmojiVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _loadChatHistory();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    currentUserId = await storage.read(key: 'user_id');
  }

  Future<void> _loadChatHistory() async {
    final userId = await storage.read(key: 'user_id');
    final token = await storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse(
          'http://192.168.1.12:3000/api/v1/messages/conversation/${widget.receiverId}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> chatHistory = json.decode(response.body);
      setState(() {
        _messages.clear();
        for (var message in chatHistory) {
          _messages.add(
            ChatMessage(
              messageId: message['message_id'].toString(),
              content: message['content'],
              isImage: message['is_image'] ?? false,
              isUser: message['sender_id'].toString() == userId,
              senderId: message['sender_id'].toString(),
              senderName: message['sender']['username'],
            ),
          );
        }
      });
      _scrollToBottom();
    }
  }

  Widget _buildMessage(ChatMessage message) {
    final bool isMyMessage = message.senderId == currentUserId;
    if (message.isImage) {
      return _buildImageMessage(message, isMyMessage);
    }
    return _buildTextMessage(message, isMyMessage);
  }

  Widget _buildTextMessage(ChatMessage message, bool isMyMessage) {
    Widget messageContent = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMyMessage
              ? [const Color(0xFF455A64), const Color(0xFF37474F)]
              : [const Color(0xFF546E7A), const Color(0xFF455A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMyMessage ? 16 : 0),
          bottomRight: Radius.circular(isMyMessage ? 0 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.content,
        style: const TextStyle(color: Colors.white70, fontSize: 15),
      ),
    );

    if (!isMyMessage) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row: Avatar with sender's name.
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blueGrey.shade700,
                  child: const Icon(Icons.person_outline,
                      color: Colors.white70, size: 22),
                ),
                const SizedBox(width: 8),
                Text(
                  message.senderName,
                  style: const TextStyle(
                    color: Color(0xFFF6D533),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Message content.
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(child: messageContent),
              ],
            ),
          ],
        ),
      );
    } else {
      // For current user's messages, enable long press to delete.
      return GestureDetector(
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title:
              const Text('Delete Message', style: TextStyle(color: Colors.white70)),
              content: const Text('Do you want to delete this message?',
                  style: TextStyle(color: Colors.white54)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    _deleteMessage(message.messageId);
                    Navigator.pop(context);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(child: messageContent),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blueGrey.shade800,
                child: const Text(
                  "Me",
                  style: TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildImageMessage(ChatMessage message, bool isMyMessage) {
    Widget imageWidget = Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment:
        isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMyMessage)
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blueGrey.shade700,
              child: const Icon(Icons.person_outline,
                  color: Colors.white70, size: 22),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black.withOpacity(0.2),
                child: Image.network(
                  message.content,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[400],
                      height: 150,
                      width: 150,
                      child: const Center(
                          child:
                          Icon(Icons.broken_image, color: Colors.white70)),
                    );
                  },
                ),
              ),
            ),
          ),
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blueGrey.shade800,
              child: const Icon(Icons.person, color: Colors.white38, size: 22),
            ),
          ],
        ],
      ),
    );

    if (isMyMessage) {
      return GestureDetector(
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: const Text('Delete Message',
                  style: TextStyle(color: Colors.white70)),
              content: const Text('Do you want to delete this message?',
                  style: TextStyle(color: Colors.white54)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    _deleteMessage(message.messageId);
                    Navigator.pop(context);
                  },
                  child:
                  const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
        },
        child: imageWidget,
      );
    } else {
      return imageWidget;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _initializeWebSocket() async {
    final userId = await storage.read(key: 'user_id');
    currentUserId = userId;
    _channel = WebSocketChannel.connect(
        Uri.parse('ws://192.168.1.12:3000/ws/notifications?userId=$userId'));
    _channel.stream.listen((dynamic message) {
      Map<String, dynamic> parsedMessage;
      if (message is String) {
        parsedMessage = jsonDecode(message);
      } else {
        parsedMessage = Map<String, dynamic>.from(message);
      }
      switch (parsedMessage['type']) {
        case 'chat':
          setState(() {
            _messages.add(
              ChatMessage(
                messageId:
                parsedMessage['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                content: parsedMessage['content'],
                isImage: parsedMessage['isImage'] ?? false,
                isUser: parsedMessage['senderId'].toString() == currentUserId,
                senderId: parsedMessage['senderId'].toString(),
                senderName: parsedMessage['senderName'] ?? "",
              ),
            );
          });
          _scrollToBottom();
          break;
        case 'message_sent':
          setState(() {
            final index =
            _messages.lastIndexWhere((msg) => msg.messageId.startsWith('temp_'));
            if (index != -1) {
              final updatedMessage = ChatMessage(
                messageId: parsedMessage['messageId'],
                content: _messages[index].content,
                isImage: _messages[index].isImage,
                isUser: _messages[index].isUser,
                senderId: _messages[index].senderId,
                senderName: _messages[index].senderName,
              );
              _messages[index] = updatedMessage;
            }
          });
          break;
        case 'delete_message':
          setState(() {
            _messages.removeWhere(
                    (message) => message.messageId == parsedMessage['messageId'].toString());
          });
          break;
        case 'error':
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(parsedMessage['message']),
              backgroundColor: Colors.red,
            ),
          );
          break;
        case 'success':
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(parsedMessage['message']),
              backgroundColor: Colors.green,
            ),
          );
          break;
      }
    }, onError: (error) {
      print('WebSocket error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection error'),
          backgroundColor: Colors.red,
        ),
      );
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
      await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        setState(() {
          _messages.add(
            ChatMessage(
              messageId: tempId,
              content: pickedFile.path,
              isImage: true,
              isUser: true,
              senderId: currentUserId ?? '',
              senderName: "Me",
            ),
          );
        });
        _channel.sink.add(jsonEncode({
          'type': 'chat',
          'senderId': currentUserId,
          'receiverId': widget.receiverId,
          'content': pickedFile.path,
          'isImage': true,
          'tempId': tempId,
        }));
        _scrollToBottom();
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final token = await storage.read(key: 'jwt_token');
    final userId = await storage.read(key: 'user_id');
    try {
      _channel.sink.add(jsonEncode({
        'type': 'delete_message',
        'messageId': messageId,
        'senderId': userId,
        'receiverId': widget.receiverId,
      }));
      setState(() {
        _messages.removeWhere((message) => message.messageId == messageId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete message'),
          backgroundColor: Colors.red,
        ),
      );
      await _loadChatHistory();
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final userId = await storage.read(key: 'user_id');
    if (userId == null) return;
    String message = _messageController.text.trim();
    String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _messages.add(
        ChatMessage(
          messageId: tempId,
          content: message,
          isImage: false,
          isUser: true,
          senderId: userId,
          senderName: "Me",
        ),
      );
    });
    final messagePayload = jsonEncode({
      'type': 'chat',
      'senderId': userId,
      'receiverId': widget.receiverId,
      'content': message,
      'isImage': false,
      'tempId': tempId,
    });
    _channel.sink.add(messagePayload);
    _messageController.clear();
    _scrollToBottom();
  }

  void _toggleEmojiKeyboard() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isEmojiVisible = !_isEmojiVisible;
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // استخدم Stack لاحتواء الخلفية مع أيقونة باهتة والواجهة الرئيسية
      body: Stack(
        children: [
          // الخلفية مع تدرج ألوان أخف
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF3A4A5A),
                  Color(0xFF4A5A6A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // أيقونة باهتة في منتصف الخلفية
          Center(
            child: Icon(
              Icons.headset_mic_outlined,
              size: 150,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          // المحتوى فوق الخلفية
          SafeArea(
            child: Column(
              children: [
                // Header / AppBar
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2C3E50),
                        Color(0xFF34495E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: const Color(0xFFF6D533),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF2C3E50),
                        child: Icon(Icons.headset_mic_outlined,
                            color: Color(0xFFF6D533)),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Customer Service',
                        style: TextStyle(
                          color: Color(0xFFF6D533),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
                ),
                // Input Field
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    boxShadow: const [
                      BoxShadow(
                        offset: Offset(0, -3),
                        blurRadius: 6,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library_rounded),
                        color: Colors.pinkAccent,
                        onPressed: _pickImage,
                      ),
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined),
                        color: Colors.yellowAccent,
                        onPressed: _toggleEmojiKeyboard,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white70),
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            onTap: () {
                              if (_isEmojiVisible) {
                                setState(() {
                                  _isEmojiVisible = false;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded),
                        color: Colors.greenAccent,
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
                _isEmojiVisible
                    ? SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      setState(() {
                        _messageController.text += emoji.emoji;
                      });
                    },
                    config: const Config(
                      columns: 7,
                      emojiSizeMax: 32,
                      verticalSpacing: 0,
                      horizontalSpacing: 0,
                      initCategory: Category.SMILEYS,
                      bgColor: Color(0xFF2E3E4E),
                      indicatorColor: Colors.yellowAccent,
                      iconColor: Colors.grey,
                      iconColorSelected: Colors.yellowAccent,
                      backspaceColor: Colors.redAccent,
                      skinToneDialogBgColor: Colors.grey,
                      enableSkinTones: true,
                    ),
                  ),
                )
                    : Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String messageId;
  final String content;
  final bool isImage;
  final bool isUser;
  final String senderId;
  final String senderName;
  ChatMessage({
    required this.messageId,
    required this.content,
    required this.isImage,
    required this.isUser,
    required this.senderId,
    required this.senderName,
  });
}
