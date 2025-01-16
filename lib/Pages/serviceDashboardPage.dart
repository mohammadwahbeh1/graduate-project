import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:untitled/Pages/serviceChatPage.dart';

class Conversation {
  final int userId;
  final String username;
  final Message lastMessage;

  Conversation({
    required this.userId,
    required this.username,
    required this.lastMessage,
  });
}

class ServiceDashboardPage extends StatefulWidget {
  const ServiceDashboardPage({Key? key}) : super(key: key);

  @override
  _ServiceDashboardPageState createState() => _ServiceDashboardPageState();
}

class _ServiceDashboardPageState extends State<ServiceDashboardPage> {
  late Future<List<Conversation>> _conversationsFuture;
  late WebSocketChannel _channel;
  static const storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _conversationsFuture = fetchMessages();
    _initializeWebSocket();
  }

  void _initializeWebSocket() async {
    final supporterId = await storage.read(key: 'user_id');
    print('Support ID: $supporterId');

    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.1.12:3000/ws/notifications?userId=$supporterId'),
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
        case 'delete_message':
        case 'message_sent':
          setState(() {
            _conversationsFuture = fetchMessages();
          });
          break;
      }
    });
  }

  Future<List<Conversation>> fetchMessages() async {
    print("Fetching messages...");
    String? token = await storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('http://192.168.1.12:3000/api/v1/messages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      List<Message> messages = jsonResponse
          .where((message) => message != null)
          .map((message) => Message.fromJson(message))
          .toList();

      final supporterId = await storage.read(key: 'user_id');
      final supporterIdInt = int.parse(supporterId ?? '13');

      Map<int, Conversation> conversations = {};

      for (var message in messages) {
        int otherUserId = message.senderId == supporterIdInt
            ? message.receiverId
            : message.senderId;

        if (!conversations.containsKey(otherUserId) ||
            DateTime.parse(message.timestamp)
                .isAfter(DateTime.parse(conversations[otherUserId]!.lastMessage.timestamp))) {
          conversations[otherUserId] = Conversation(
            userId: otherUserId,
            username: message.senderName,
            lastMessage: message,
          );
        }
      }

      return conversations.values.toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252525),
        title: const Text(
          'Service Dashboard',
          style: TextStyle(color: Color(0xFFF6D533)),
        ),
        elevation: 0,
      ),
      body: FutureBuilder<List<Conversation>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No conversations found', style: TextStyle(color: Colors.white)));
          } else {
            List<Conversation> conversations = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ChatUserCard(message: conversation.lastMessage);
              },
            );
          }
        },
      ),
    );
  }
}

class Message {
  final int messageId;
  final int senderId;
  final int receiverId;
  final String content;
  final bool isImage;
  final String timestamp;
  final bool isRead;
  final String senderName;

  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isImage,
    required this.timestamp,
    required this.isRead,
    required this.senderName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['message_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      isImage: json['is_image'],
      timestamp: json['timestamp'],
      isRead: json['is_read'],
      senderName: json['sender']['username'],
    );
  }
}

class ChatUserCard extends StatelessWidget {
  final Message message;

  const ChatUserCard({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceChatPage(receiverId: message.senderId.toString()),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // A subtle gradient background for a modern look.
          gradient: const LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFF373737)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFF6D533),
            radius: 28,
            child: Text(
              message.senderName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          title: Text(
            message.senderName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              message.content,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message.timestamp,
                style: const TextStyle(
                  color: Color(0xFFF6D533),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              if (!message.isRead)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6D533),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
