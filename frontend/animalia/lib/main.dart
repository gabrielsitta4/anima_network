import 'package:animalia/views/feed_page/feed_page.dart';
import 'package:animalia/views/home_page/home_page.dart';
import 'package:animalia/views/login_page/login_page.dart';
import 'package:animalia/views/onboarding_page/onboarding_page.dart';
import 'package:animalia/views/register_page/register_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: OnboardingPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/homepage': (context) => HomePage(),
        '/feed': (context) => FeedPage(),
      },
    );
  }
}
