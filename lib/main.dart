import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neighborhood_safety_network/pages/alerts_page.dart';
import 'package:neighborhood_safety_network/pages/profile_page.dart';
import 'package:neighborhood_safety_network/pages/silent_alert_page.dart';
import 'package:pandabar/main.view.dart';
import 'package:pandabar/pandabar.dart';
import 'pages/home_page.dart';
import 'pages/alerts_page.dart';
import 'pages/silent_alert_page.dart';
import 'pages/profile_page.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  String page = 'Home';

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

        onFabButtonPressed: () {
          showCupertinoDialog(
            context: context,
            builder: (context) {
              return CupertinoAlertDialog(
                content: Text('Confirm sending SOS?'),
                actions: <Widget>[
                  CupertinoDialogAction(
                    child: Text('Confirm'),
                    isDestructiveAction: true,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                ],
              );
            }
          );
        },
      ),
      body: _getPage(),
    );
  }
}

//test edit