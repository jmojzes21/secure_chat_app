import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'logic/auth_service.dart';
import 'logic/chat_service.dart';
import 'pages/login_page.dart';

void main() {
  if (kDebugMode) {
    runApp(MultiApp());
  } else {
    runApp(MainApp());
  }
}

class MultiApp extends StatelessWidget {
  const MultiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Row(
          children: [
            Expanded(child: MainApp()),
            VerticalDivider(),
            Expanded(child: MainApp()),
          ],
        ),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => AuthService(),
      child: ChangeNotifierProvider(
        create: (context) => ChatService(context.read<AuthService>()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.blue,
            appBarTheme: AppBarTheme(backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white),
            scaffoldBackgroundColor: Colors.white,
          ),
          home: LoginPage(),
        ),
      ),
    );
  }
}
