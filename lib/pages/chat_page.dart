import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../logic/chat_service.dart';
import '../logic/exceptions.dart';
import '../models/message.dart';
import '../models/user_chat.dart';
import '../widgets/dialogs.dart';

class ChatPage extends StatefulWidget {
  final UserChat userChat;
  const ChatPage({super.key, required this.userChat});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final tecMessage = TextEditingController();
  final focusNode = FocusNode(canRequestFocus: true);

  late UserChat userChat;

  @override
  void initState() {
    super.initState();
    userChat = widget.userChat;
  }

  void sendMessage() async {
    var message = tecMessage.text.trim();
    if (message.isEmpty) return;

    tecMessage.clear();
    var chatService = context.read<ChatService>();

    try {
      await chatService.sendMessage(userChat, message);
      setState(() {});
    } catch (e) {
      var msg = AppException.getMessage(e);
      log(msg);
      if (!mounted) return;
      Dialogs.showSnackBar(context, msg);
    }
  }

  void exchangeSecretKey() async {
    var chatService = context.read<ChatService>();

    try {
      await chatService.exchangeKey(userChat);
    } catch (e) {
      var msg = AppException.getMessage(e);
      log(msg);
      if (!mounted) return;
      Dialogs.showSnackBar(context, msg);
    }
  }

  void deleteChat() async {
    var chatService = context.read<ChatService>();

    try {
      await chatService.deleteChat(userChat);
    } catch (e) {
      var msg = AppException.getMessage(e);
      log(msg);
      if (!mounted) return;
      Dialogs.showSnackBar(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userChat.otherUser.name),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(FontAwesomeIcons.user),
              SizedBox(width: 10),
              Text(widget.userChat.currentUser.name),
              SizedBox(width: 20),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Consumer<ChatService>(
          builder: (context, model, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _MessageViewWidget(messages: userChat.messages)),
                SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tecMessage,
                        focusNode: focusNode,
                        autofocus: true,
                        onSubmitted: (value) {
                          sendMessage();
                          focusNode.requestFocus();
                        },
                        decoration: InputDecoration(hintText: 'Poruka', isDense: true, border: OutlineInputBorder()),
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(onPressed: () => sendMessage(), icon: FaIcon(FontAwesomeIcons.paperPlane)),
                  ],
                ),
                SizedBox(height: 20),

                ExpansionTile(
                  title: Text('Sigurnost'),
                  leading: FaIcon(FontAwesomeIcons.lock),
                  expandedAlignment: Alignment.topLeft,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  childrenPadding: EdgeInsets.only(top: 10, bottom: 40),
                  children: [
                    Text(
                      'Tajni ključ: ${userChat.secretKeyText ?? 'ne postoji'}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => exchangeSecretKey(),
                      icon: FaIcon(FontAwesomeIcons.key),
                      label: Text('Razmjeni novi ključ'),
                    ),
                    SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => deleteChat(),
                      icon: FaIcon(FontAwesomeIcons.trashCan),
                      label: Text('Obriši razgovor'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    tecMessage.dispose();
    focusNode.dispose();
    super.dispose();
  }
}

class _MessageViewWidget extends StatefulWidget {
  final List<Message> messages;

  const _MessageViewWidget({required this.messages});

  @override
  State<_MessageViewWidget> createState() => _MessageViewWidgetState();
}

class _MessageViewWidgetState extends State<_MessageViewWidget> {
  var scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  @override
  void didUpdateWidget(covariant _MessageViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.biggest.width,
          height: constraints.biggest.height,
          color: Colors.grey.shade50,
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: widget.messages.map((e) => buildMessageWidget(e)).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildMessageWidget(Message message) {
    var backgroundColor = message.isReceived ? Colors.yellow.shade200 : Colors.blue.shade800;
    var textColor = message.isReceived ? Colors.black : Colors.white;
    var alignment = message.isReceived ? Alignment.topLeft : Alignment.topRight;

    return Align(
      alignment: alignment,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(10)),
        child: Text(message.value, style: TextStyle(fontSize: 16, color: textColor)),
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
