import 'dart:convert';
import 'dart:typed_data';

import 'key_exchange.dart';
import 'message.dart';
import 'user.dart';

class UserChat {
  User currentUser;
  User otherUser;

  Uint8List? secretKey;
  String? secretKeyText;

  KeyExchange? keyExchange;

  List<Message> messages = [];

  UserChat({required this.currentUser, required this.otherUser});

  void addSentMessage(String message) {
    messages.add(Message.sent(message));
  }

  void addReceivedMessage(String message) {
    messages.add(Message.received(message));
  }

  void deleteMessages() {
    messages.clear();
  }

  Map<String, dynamic> toJson() {
    return {'user': otherUser.toJson(), 'messages': messages.map((e) => e.toJson()).toList()};
  }

  factory UserChat.fromJson(Map<String, dynamic> json, User currentUser) {
    var messages = (json['messages'] as List<dynamic>).map((e) => Message.fromJson(e)).toList();

    var userChat = UserChat(currentUser: currentUser, otherUser: User.fromJson(json['user']));
    userChat.messages.addAll(messages);
    return userChat;
  }

  void updateSecretKey(Uint8List secretKey) {
    this.secretKey = secretKey;
    secretKeyText = base64.encode(secretKey);
  }
}
