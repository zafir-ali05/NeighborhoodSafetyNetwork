import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart'; // Generated by flutterfire
import 'package:pandabar/pandabar.dart';
import 'pages/home_page.dart';
import 'pages/alerts_page.dart';
import 'pages/silent_alert_page.dart';
import 'pages/profile_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/emergency_contact.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // register adapter and open hive box
  Hive.registerAdapter(EmergencyContactAdapter());
  await Hive.openBox<EmergencyContact>('contacts'); 

  // firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPage()
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FlutterTts flutterTts = FlutterTts();
  String page = 'Home';

  Future<void> _makePhoneCall(String phoneNumber) async {
  // Format the phone number with proper URI encoding
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber.replaceAll(RegExp(r'[^\d+]'), ''),
  );
  
  try {
    if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $launchUri';
    }
  } catch (e) {
    print('Error making phone call: $e');
    // Show error dialog
    if (context.mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Error'),
          content: Text('Failed to make phone call. Please try again.'),
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

  Future<void> _speak(String message) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(message);
  }

  Widget _getPage() {
    switch (page) {
      case 'Home':
        return HomePageContent();
      case 'Alerts':
        return AlertsPage();
      case 'Silent Alert':
        return SilentAlertPage();
      case 'Profile':
        return ProfilePage();
      default:
        return HomePageContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: PandaBar(
        buttonData: [
          PandaBarButtonData(
            id: 'Home',
            icon: Icons.home,
            title: 'Home',
          ),
          PandaBarButtonData(
            id: 'Alerts',
            icon: Icons.crisis_alert,
            title: 'Alerts'
          ),
          PandaBarButtonData(
            id: 'Silent Alert',
            icon: Icons.notifications_off,
            title: 'Silent Alert'
          ),
          PandaBarButtonData(
            id: 'Profile',
            icon: Icons.person,
            title: 'Profile'
          ),
        ],
        fabIcon: Icon(
          Icons.sos_outlined,
          color: const Color.fromARGB(255, 255, 255, 255),
        ), //FAB ICON
        fabColors: [
          Colors.red.shade900,
          Colors.red.shade900,
          Colors.red.shade900,
          Colors.red.shade900,
        ], // FAB COLOURS
        onChange: (id) {
          setState(() {
            page = id;
          });
        },

        onFabButtonPressed: () async {
          try {
            await showCupertinoDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return CupertinoAlertDialog(
                  title: Text('Emergency Alert'),
                  content: Text('Confirm sending SOS?'),
                  actions: <Widget>[
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () async {
                        Navigator.pop(context);
                        await _makePhoneCall('5197668359');
                        await _speak("This is an emergency. Please send help immediately.");
                      },
                      child: Text('Confirm'),
                    ),
                    CupertinoDialogAction(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              },
            );
          } catch (e) {
            print('Error showing dialog: $e');
          }
        },
      ),
      body: _getPage(),
    );
  }
}