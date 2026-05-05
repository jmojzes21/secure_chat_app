import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../logic/auth_service.dart';
import '../logic/exceptions.dart';
import '../widgets/dialogs.dart';
import 'users_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final tecUsername = TextEditingController();
  final tecPassword = TextEditingController();
  bool showPassword = false;

  void setPasswordVisible(bool visible) {
    setState(() {
      showPassword = visible;
    });
  }

  void login() async {
    String username = tecUsername.text.trim();
    String password = tecPassword.text.trim();

    var authService = context.read<AuthService>();

    try {
      await authService.login(username, password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => UsersPage()));
    } catch (e) {
      var msg = AppException.getMessage(e);
      log(msg);
      Dialogs.showSnackBar(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prijava')),
      body: Center(
        child: Card(
          color: Colors.grey.shade50,
          child: Padding(
            padding: EdgeInsets.all(80),
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tecUsername,
                    decoration: InputDecoration(
                      label: Text('Korisničko ime'),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: tecPassword,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      label: Text('Lozinka'),
                      isDense: true,
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setPasswordVisible(!showPassword),
                        icon: !showPassword
                            ? FaIcon(FontAwesomeIcons.solidEye)
                            : FaIcon(FontAwesomeIcons.solidEyeSlash),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  FilledButton(onPressed: () => login(), child: Text('Prijava')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    tecUsername.dispose();
    tecPassword.dispose();
    super.dispose();
  }
}
