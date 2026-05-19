import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/logs_provider.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize notifications
    await NotificationService.initialize();
    
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => LogsProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraRelief',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7A9E8A)),
        useMaterial3: true,
      ),

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          
          if (snapshot.hasData) {
            return const MainScreen();
          }

          
          return const LoginScreen();
        },
      ),
    );
  }
}
