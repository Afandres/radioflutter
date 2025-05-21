import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Importa SharedPreferences

// Modelo de mensaje ajustado a tu JSON
class ChatMessage {
  final String message;
  final DateTime timestamp;
  final String user;

  ChatMessage({
    required this.message,
    required this.timestamp,
    required this.user,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      message: json['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000),
      user: json['user'] ?? 'Anonimo',
    );
  }
}

// Servicio para interactuar con la API
class ChatService {
  final String baseUrl =
      'http://192.168.100.147:8081/api'; // Cambia esto por tu dominio real

  Future<List<ChatMessage>> getMessages() async {
    final response = await http.get(Uri.parse('$baseUrl/messages'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los mensajes');
    }
  }

  Future<void> sendMessage(String text, String user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'text': text,
        'user': user,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al enviar mensaje');
    }
  }
}

// Pantalla del chat
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  Timer? _timer;
  String _user = 'Anonimo'; // Valor por defecto

  @override
  void initState() {
    super.initState();
    _loadUserFromPreferences().then((_) {
      _loadMessages();

      _timer = Timer.periodic(Duration(seconds: 10), (timer) {
        _loadMessages();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('username') ??
        'Anonimo'; // Cambia 'username' por la key que usas
    setState(() {
      _user = user;
    });
  }

  void _loadMessages() async {
    try {
      setState(() => _loading = true);
      final messages = await _chatService.getMessages();
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } catch (e) {
      print('Error al cargar mensajes: $e');
      setState(() => _loading = false);
    }
  }

  void _sendMessage() async {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      await _chatService.sendMessage(text, _user);
      _controller.clear();
      _loadMessages();
    } catch (e) {
      print('Error al enviar mensaje: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar el mensaje')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat con API"),
        backgroundColor: Colors.green.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final formattedTime =
                          "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}";
                      return ListTile(
                        title: Text(message.message),
                        subtitle: Text('${message.user} • $formattedTime'),
                        leading: Icon(Icons.message, color: Colors.green),
                      );
                    },
                  ),
          ),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.green.shade900),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
