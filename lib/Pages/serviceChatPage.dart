import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final userId = await storage.read(key: 'user_id');
    final token = await storage.read(key: 'jwt_token');

    final response = await http.get(
      Uri.parse('http://192.168.1.12:3000/api/v1/messages/conversation/${widget.receiverId}'),
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
          _messages.add(ChatMessage(
            content: message['content'],
            isImage: message['is_image'] ?? false,
            isUser: message['sender_id'].toString() == userId,
          ));
        }
      });
      _scrollToBottom();
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

    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.1.12:3000/ws/notifications?userId=$userId'),
    );

    _channel.stream.listen((message) {
      final parsedMessage = jsonDecode(message);
      if (parsedMessage['type'] == 'chat' &&
          (parsedMessage['senderId'] == widget.receiverId ||
              parsedMessage['receiverId'] == widget.receiverId)) {
        setState(() {
          _messages.add(ChatMessage(
            content: parsedMessage['content'],
            isImage: false,
            isUser: parsedMessage['senderId'] == userId,
          ));
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userId = await storage.read(key: 'user_id');
    String message = _messageController.text.trim();

    final messagePayload = jsonEncode({
      'type': 'chat',
      'senderId': userId,
      'receiverId': widget.receiverId,
      'content': message,
    });

    _channel.sink.add(messagePayload);

    setState(() {
      _messages.add(ChatMessage(
        content: message,
        isImage: false,
        isUser: true,
      ));
    });

    _messageController.clear();
    _scrollToBottom();
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
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252525),
        title: const Text(
          'Customer Service',
          style: TextStyle(color: Color(0xFFF6D533)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF6D533)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Align(
                    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: message.isUser ? const Color(0xffffffff) : const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: message.isUser ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF252525),
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black26,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo),
                    color: const Color(0xFFF6D533),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: const Color(0xFFF6D533),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isImage;
  final bool isUser;

  ChatMessage({
    required this.content,
    required this.isImage,
    required this.isUser,
  });
}
