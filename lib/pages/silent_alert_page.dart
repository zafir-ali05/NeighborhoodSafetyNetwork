import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
// Remove cloud_firestore import if no longer used
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emergency_contact.dart';

class SilentAlertPage extends StatefulWidget {
  const SilentAlertPage({super.key});

  @override
  _SilentAlertPageState createState() => _SilentAlertPageState();
}

class _SilentAlertPageState extends State<SilentAlertPage> {
  final TextEditingController _messageController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  bool _isSending = false;
  List<ChatMessage> messages = [];

  // Predefined quick messages (unchanged)
  final List<String> quickMessages = [
    "Severe Domestic Situation - Alert authorities",
    "Under duress - Alert authorities",
    "Someone is following me - Pick me up",
    "Need help - Feel unsafe",
  ];

  void _selectQuickMessage(String message) {
    _messageController.text = message;
  }

  @override
  void initState() {
    super.initState();
    messages.add(ChatMessage(
      message:
          "Please enter your current situation/issue; be as descriptive as possible",
      isUser: false,
    ));
    messages.add(ChatMessage(
      message:
          "The message you send will be sent as an SMS to emergency services & emergency contacts",
      isUser: false,
    ));
  }

  /// Updated: Retrieve all emergency contact numbers from the Hive box.
  Future<List<String>> _getEmergencyContactNumbers() async {
    try {
      final Box<EmergencyContact> contactsBox =
          Hive.box<EmergencyContact>('contacts');
      return contactsBox.values.map((contact) => contact.phone).toList();
    } catch (e) {
      print('Error fetching emergency contacts from Hive: $e');
      return [];
    }
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Location Services Disabled'),
            content: Text(
                'Please enable location services to send your location with the alert.'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Updated _sendSMS: send alert only to emergency contacts retrieved from Hive.
  Future<void> _sendSMS(String dummyEmergencyNumber, String message) async {
    try {
      setState(() => _isSending = true);
      
      // Get current location, if available.
      final Position? position = await _getCurrentLocation();
      String fullMessage = 'EMERGENCY ALERT: $message\n\n';
      
      if (position != null) {
        fullMessage += 'My current location:\n';
        fullMessage +=
            'https://www.google.com/maps?q=${position.latitude},${position.longitude}\n\n';
      }
      
      fullMessage += 'This is an emergency message from Neighborhood Safety Network.';
      
      // Retrieve all emergency contacts from Hive
      final List<String> emergencyContacts = await _getEmergencyContactNumbers();
      
      if (emergencyContacts.isEmpty) {
        // If no contacts are available, you can optionally show an error.
        throw 'No emergency contacts found.';
      }
      
      // Create a group recipient string for all contacts.
      final String groupRecipients = emergencyContacts.join(';');
      
      // Construct the SMS URI.
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: groupRecipients,
        queryParameters: {'body': fullMessage},
      );
      
      if (!await launchUrl(smsUri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch SMS';
      }
      
      setState(() {
        _isSending = false;
        messages.add(ChatMessage(
          message: position != null
              ? "Emergency message and location sent to all emergency contacts"
              : "Emergency message sent to all emergency contacts",
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
            content: Text(
                'Failed to send emergency messages. Please try again. \nError: $e'),
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

    // The hardcoded number is now ignored because _sendSMS sends to all Hive contacts.
    _sendSMS('5197668359', message);
  }

  @override
  Widget build(BuildContext context) {
    // The UI remains unchanged.
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
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[messages.length - 1 - index];
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
              height: 50,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: quickMessages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _selectQuickMessage(quickMessages[index]),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 3,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            quickMessages[index],
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
                      onTap: _isSending
                          ? null
                          : () => _handleSubmit(_messageController.text),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.send,
                            color: Colors.white, size: 24),
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
  }) : timestamp = timestamp ?? DateTime.now();
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  const MessageBubble({super.key, 
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
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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