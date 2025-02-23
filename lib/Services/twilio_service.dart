import 'package:http/http.dart' as http;
import 'dart:convert';

class TwilioService {
  final String accountSid = 'ACcc97ae45787b193a45811778606ba9d9';
  final String authToken = 'bd960ad6b4cb7fd089fc22e3cd83d185';
  final String fromNumber = '+19057180619';
  final String toNumber = '+15197668359'; // Replace with the recipient's phone number

  Future<void> makeCall() async {
    final String url = 'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Calls.json';
    final String basicAuth = 'Basic ' + base64Encode(utf8.encode('$accountSid:$authToken'));

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': basicAuth,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'From': fromNumber,
        'To': toNumber,
        'Url': 'http://demo.twilio.com/docs/voice.xml', // URL to TwiML instructions
      },
    );

    if (response.statusCode == 201) {
      print('Call initiated successfully');
    } else {
      print('Failed to initiate call: ${response.statusCode} - ${response.body}');
    }
  }
}