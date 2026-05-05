import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../logic/auth_service.dart';
import '../logic/chat_service.dart';
import '../logic/exceptions.dart';
import '../logic/user_service.dart';
import '../models/user.dart';
import '../widgets/dialogs.dart';
import 'chat_page.dart';
import 'login_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late User currentUser;
  List<User> users = [];

  @override
  void initState() {
    super.initState();

    var authService = context.read<AuthService>();
    currentUser = authService.currentUser;

    loadUsers();
  }

  void loadUsers() async {
    var chatService = context.read<ChatService>();
    var userService = UserService();

    try {
      var users = await userService.getFriends(currentUser.username);

      await chatService.loadUsers(users);
      await chatService.connect();

      setState(() {
        this.users = users;
      });
    } catch (e) {
      var msg = AppException.getMessage(e);
      log(msg);
      if (!mounted) return;
      Dialogs.showSnackBar(context, msg);
    }
  }

  void openChat(User user) {
    var chatService = context.read<ChatService>();
    var userChat = chatService.getUserChat(user.username);
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatPage(userChat: userChat)));
  }

  void logout() {
    var authService = context.read<AuthService>();
    var chatService = context.read<ChatService>();

    try {
      authService.logout();
      chatService.disconnect();
    } catch (e) {
      var msg = AppException.getMessage(e);
      log(msg);
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Korisnici'),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [FaIcon(FontAwesomeIcons.user), SizedBox(width: 10), Text(currentUser.name), SizedBox(width: 20)],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prijavljeni korisnik', style: Theme.of(context).textTheme.titleLarge),
              ListTile(title: Text(currentUser.name), leading: FaIcon(FontAwesomeIcons.user)),
              TextButton(onPressed: () => logout(), child: Text('Odjava')),
              SizedBox(height: 20),
              Text('Korisnici', style: Theme.of(context).textTheme.titleLarge),
              ...users.map((User e) {
                return ListTile(onTap: () => openChat(e), title: Text(e.name), leading: FaIcon(FontAwesomeIcons.user));
              }),
            ],
          ),
        ),
      ),
    );
  }
}
