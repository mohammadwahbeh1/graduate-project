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
  String? currentUserId;

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
      Uri.parse('http://192.168.1.8:3000/api/v1/messages/conversation/${widget.receiverId}'),
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
            messageId: message['message_id'].toString(),
            content: message['content'],
            isImage: message['is_image'] ?? false,
            isUser: message['sender_id'].toString() == userId,
            senderId: message['sender_id'].toString(),
          ));
        }
      });
      _scrollToBottom();
    }
  }

  Widget _buildMessage(ChatMessage message) {
    return GestureDetector(
      onLongPress: message.senderId == currentUserId ? () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF252525),
            title: const Text(
              'Delete Message',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Do you want to delete this message?',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFFF6D533)),
                ),
              ),
              TextButton(
                onPressed: () {
                  _deleteMessage(message.messageId);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      } : null,
      child: Padding(
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
      ),
    );
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
      Uri.parse('ws://192.168.1.8:3000/ws/notifications?userId=$userId'),
    );

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
            _messages.add(ChatMessage(
              messageId: parsedMessage['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              content: parsedMessage['content'],
              isImage: false,
              isUser: parsedMessage['senderId'] == userId,
              senderId: parsedMessage['senderId'],
            ));
          });
          _scrollToBottom();
          break;

        case 'message_sent':
          setState(() {
            final index = _messages.lastIndexWhere((msg) => msg.messageId.startsWith('temp_'));
            if (index != -1) {
              final updatedMessage = ChatMessage(
                messageId: parsedMessage['messageId'],
                content: _messages[index].content,
                isImage: _messages[index].isImage,
                isUser: _messages[index].isUser,
                senderId: _messages[index].senderId,
              );
              _messages[index] = updatedMessage;
            }
          });
          break;

        case 'delete_message':
          print('Received delete message: ${parsedMessage['messageId']}');
          setState(() {
            _messages.removeWhere((message) =>
            message.messageId == parsedMessage['messageId'].toString());
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
          content: Text('Connection error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }, onDone: () {
      print('WebSocket connection closed');
      // Optional: Implement reconnection logic here
    });
  }


  Future<void> _deleteMessage(String messageId) async {
    final token = await storage.read(key: 'jwt_token');
    final userId = await storage.read(key: 'user_id');

    try {
      // Send WebSocket delete request first
      _channel.sink.add(jsonEncode({
        'type': 'delete_message',
        'messageId': messageId,
        'senderId': userId,
        'receiverId': widget.receiverId,
      }));

      // Remove message locally
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
      // Reload chat history on error
      await _loadChatHistory();
    }
  }




  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userId = await storage.read(key: 'user_id');
    if (userId == null) return;
    String message = _messageController.text.trim();
    String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Add message with temporary ID
    setState(() {
      _messages.add(ChatMessage(
        messageId: tempId,
        content: message,
        isImage: false,
        isUser: true,
        senderId: userId,
      ));
    });

    final messagePayload = jsonEncode({
      'type': 'chat',
      'senderId': userId,
      'receiverId': widget.receiverId,
      'content': message,
      'tempId': tempId,  // Include tempId in the payload
    });

    _channel.sink.add(messagePayload);
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
                return _buildMessage(_messages[index]);
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
  final String messageId;
  final String content;
  final bool isImage;
  final bool isUser;
  final String senderId;

  ChatMessage({
    required this.messageId,
    required this.content,
    required this.isImage,
    required this.isUser,
    required this.senderId,
  });
}
