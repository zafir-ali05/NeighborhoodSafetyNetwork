import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';  // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';  // Add this import

class SilentAlertPage extends StatefulWidget {
  @override
  _SilentAlertPageState createState() => _SilentAlertPageState();
}

class _SilentAlertPageState extends State<SilentAlertPage> {
  final TextEditingController _messageController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;  // Add this line
  bool _isSending = false;
  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    // Add initial system message
    messages.add(ChatMessage(
      message: "Please enter your current situation/issue; be as descriptive as possible",
      isUser: false,
     ));
    messages.add(ChatMessage(
      message: "The message you send will be sent as an SMS to emergency services & emergency contacts",
      isUser: false,
    ));
  }

  Future<List<String>> _getEmergencyContactNumbers() async {
    try {
      final snapshot = await _firestore.collection('emergency_contacts').get();
      return snapshot.docs.map((doc) => doc.data()['phone'] as String).toList();
    } catch (e) {
      print('Error fetching emergency contacts: $e');
      return [];
    }
  }

  Future<void> _sendSMS(String emergencyNumber, String message) async {
    try {
      setState(() => _isSending = true);
      
      // Get all emergency contact numbers
      final emergencyContacts = await _getEmergencyContactNumbers();
      
      // Create the full message
      final fullMessage = 'EMERGENCY ALERT: $message\n\nThis is an emergency message from Neighborhood Safety Network.';
      
      // Combine emergency number with contact numbers
      final allRecipients = [emergencyNumber, ...emergencyContacts];
      
      // Create SMS URI with multiple recipients
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: allRecipients.join(','),
        queryParameters: {'body': fullMessage},
      );

      if (!await launchUrl(smsUri)) {
        throw 'Could not launch SMS';
      }
      
      setState(() {
        _isSending = false;
        messages.add(ChatMessage(
          message: "Emergency message sent to all emergency contacts",
          isUser: false,
        ));
      });
    } catch (e) {
      setState(() => _isSending = false);
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Error'),
            content: Text('Failed to send emergency messages. Please try again.'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _handleSubmit(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      messages.add(ChatMessage(message: message, isUser: true));
      _messageController.clear();
    });

    _sendSMS('5197668359', message);  // Replace _makePhoneCall with _sendSMS
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Silent Alert',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                reverse: true,  // Makes the list scroll from bottom
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[messages.length - 1 - index];  // Reverse the messages
                  return MessageBubble(
                    message: message.message,
                    isUser: message.isUser,
                    timestamp: message.timestamp,
                  );
                },
              ),
            ),
            if (_isSending)
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(width: 8),
                    Text('Sending emergency alert...'),
                  ],
                ),
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Describe your situation...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  SizedBox(width: 8),
                  Material(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: _isSending ? null : () => _handleSubmit(_messageController.text),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.send, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.message, 
    required this.isUser, 
    DateTime? timestamp,
  }) : this.timestamp = timestamp ?? DateTime.now();
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  const MessageBubble({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 64 : 16,
        right: isUser ? 16 : 64,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isUser ? Colors.black87 : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 5),
                bottomRight: Radius.circular(isUser ? 5 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              message,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              DateFormat('h:mm a').format(timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}