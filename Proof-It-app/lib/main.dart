import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/welcome_screen.dart'; 
import 'pages/login_screen.dart';
import 'pages/main_layout.dart';
import 'data/mock_database.dart';
import 'models/data_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qpaicltxcyzuluciidpe.supabase.co',
    anonKey:
        'sb_publishable_96ZmWPRM4-68gSs17HGZZw_ybFLpuWe',
  );

  Widget initialScreen = const WelcomeScreen();
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final userDataStr = prefs.getString('user_data');

    if (token != null && userDataStr != null) {
      final userData = jsonDecode(userDataStr);
      
      UserRole roleEnum = UserRole.Member;
      if (userData['role'] == 'Admin') roleEnum = UserRole.Admin;
      if (userData['role'] == 'PIC') roleEnum = UserRole.PIC;

      AuthSession.currentUser = User(
        id: userData['id'].toString(),
        username: userData['username'].toString(),
        email: userData['email'].toString(),
        password: userData['password_hash']?.toString() ?? '',
        role: roleEnum,
      );
      
      initialScreen = const MainLayout();
    }
  } catch (e) {
    print("Error checking session: $e");
  }

  runApp(ProofItApp(initialScreen: initialScreen));
}

class ProofItApp extends StatelessWidget {
  final Widget initialScreen;
  const ProofItApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proof It!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF4F5F7),
        fontFamily: 'Segoe UI',
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }  
}
