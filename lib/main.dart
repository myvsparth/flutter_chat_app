import 'package:flutter/material.dart';
import 'package:flutter_chat_app/pages/home_page.dart';
import 'package:flutter_chat_app/pages/registration_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.getInstance().then((prefs) {
    runApp(LandingPage(prefs: prefs));
  });
}

class LandingPage extends StatelessWidget {
  final SharedPreferences prefs;
  LandingPage({this.prefs});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _decideMainPage(),
    );
  }

  _decideMainPage() {
    if (prefs.getBool('is_verified') != null) {
      if (prefs.getBool('is_verified')) {
        return HomePage(prefs: prefs);
        // return RegistrationPage(prefs: prefs);
      } else {
        return RegistrationPage(prefs: prefs);
      }
    } else {
      return RegistrationPage(prefs: prefs);
    }
  }
}
