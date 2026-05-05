import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/key_exchange.dart';
import '../models/user.dart';
import '../models/user_chat.dart';
import 'auth_service.dart';
import 'backend_context.dart';
import 'byte_data_buffer.dart';
import 'chat_repository.dart';
import 'crypto_service.dart';
import 'exceptions.dart';
import 'key_exchange_service.dart';
import 'op_protocol.dart';

class ChatService extends ChangeNotifier {
  static const int opMessage = 100;
  static const int opFirstPublicKey = 120;
  static const int opSecondPublicKey = 121;
  static const int opConfirmKeyExchange = 122;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;

  final Map<String, UserChat> _userChats = {};
  ChatRepository? _chatRepository;

  final AuthService _authService;

  ChatService(AuthService authService) : _authService = authService;

  Future<void> loadUsers(List<User> users) async {
    _chatRepository = ChatRepository();

    await _loadLocalUsers();

    var currentUser = _authService.currentUser;
    for (User user in users) {
      UserChat? userChat = _userChats[user.username];

      if (userChat == null) {
        _userChats[user.username] = UserChat(currentUser: currentUser, otherUser: user);
        continue;
      }

      userChat.otherUser = user;
    }
  }

  Future<void> _loadLocalUsers() async {
    var currentUser = _authService.currentUser;
    var userChats = await _chatRepository!.loadUserChats(currentUser);

    for (var userChat in userChats) {
      _userChats[userChat.otherUser.username] = userChat;
    }
  }

  Future<void> connect() async {
    var userToken = _authService.userToken;

    var url = Uri.parse('wss://${BackendContext.httpPath}/ws/chat?token=$userToken');
    _channel = WebSocketChannel.connect(url);
    await _channel!.ready;

    _channelSubscription = _channel!.stream.listen((message) {
      if (message is Uint8List) {
        try {
          _onSocketMessage(message);
        } catch (e) {
          var msg = AppException.getMessage(e);
          log(msg);
        }
      }
    });
  }

  void disconnect() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;

    _userChats.clear();
    _chatRepository = null;
  }

  Future<void> sendMessage(UserChat userChat, String message) async {
    User currentUser = userChat.currentUser;
    User recipient = userChat.otherUser;

    if (userChat.secretKey == null) {
      throw AppException('Tajni ključ za E2EE komunikaciju ne postoji!');
    }

    var cryptoService = CryptoService();

    var key = userChat.secretKey!;
    var iv = cryptoService.generateAesIv();

    String encryptedMessage = cryptoService.aesGcmEncryptText(message, key, iv);

    var buffer = ByteDataBuffer.create();
    buffer.writeString(currentUser.username);
    buffer.writeString(recipient.username);
    buffer.writeString(encryptedMessage);

    var opProtocol = OpProtocol(opMessage, buffer.data);
    var bytes = opProtocol.createRequest();

    _channel!.sink.add(bytes);

    userChat.addSentMessage(message);
    notifyListeners();

    await _chatRepository!.saveUserChat(userChat);
  }

  Future<void> exchangeKey(UserChat userChat) async {
    await _generateKeyPair(userChat);
    _sendPublicKey(userChat, opFirstPublicKey);
  }

  Future<void> deleteChat(UserChat userChat) async {
    userChat.deleteMessages();
    await _chatRepository!.saveUserChat(userChat);
    notifyListeners();
  }

  void _onSocketMessage(Uint8List socketMessage) {
    var opProtocol = OpProtocol.decode(socketMessage);

    int op = opProtocol.op;
    var buffer = ByteDataBuffer(opProtocol.payload);

    User currentUser = _authService.currentUser;

    String sender = buffer.readString();
    String recipient = buffer.readString();

    if (recipient != currentUser.username) {
      return;
    }

    switch (op) {
      case opMessage:
        String msg = buffer.readString();
        _onReceiveMessage(sender, msg);
        break;
      case opFirstPublicKey:
        String publicKey = buffer.readString();
        _onReceiveFirstPublicKey(sender, publicKey);
        break;
      case opSecondPublicKey:
        String publicKey = buffer.readString();
        _onReceiveSecondPublicKey(sender, publicKey);
      case opConfirmKeyExchange:
        _onReceiveKeyExchangeConfirmation(sender);
        break;
    }
  }

  Future<void> _onReceiveMessage(String sender, String encryptedMessage) async {
    UserChat? userChat = _userChats[sender];
    if (userChat == null) return;

    if (userChat.secretKey == null) {
      throw Exception('Nije moguće dekriptirati poruku!');
    }

    var cryptoService = CryptoService();

    var key = userChat.secretKey!;
    String message = cryptoService.aesGcmDecryptText(encryptedMessage, key);

    userChat.addReceivedMessage(message);
    notifyListeners();

    await _chatRepository!.saveUserChat(userChat);
  }

  Future<void> _onReceiveFirstPublicKey(String sender, String publicKeyText) async {
    UserChat? userChat = _userChats[sender];
    if (userChat == null) return;

    await _generateKeyPair(userChat);
    _saveRemotePublicKey(userChat, publicKeyText);
    _sendPublicKey(userChat, opSecondPublicKey);
  }

  Future<void> _onReceiveSecondPublicKey(String sender, String publicKeyText) async {
    UserChat? userChat = _userChats[sender];
    if (userChat == null) return;

    _sendKeyExchangeConfirmation(userChat);
    _saveRemotePublicKey(userChat, publicKeyText);
    await _confirmKeyExchange(userChat);
  }

  Future<void> _onReceiveKeyExchangeConfirmation(String sender) async {
    UserChat? userChat = _userChats[sender];
    if (userChat == null) return;

    await _confirmKeyExchange(userChat);
  }

  Future<void> _generateKeyPair(UserChat userChat) async {
    var keyExchangeService = KeyExchangeService();
    var keyPair = await keyExchangeService.generateKeyPair();

    userChat.keyExchange = KeyExchange();
    userChat.keyExchange!.keyPair = keyPair;
  }

  void _saveRemotePublicKey(UserChat userChat, String publicKeyText) {
    var keyExchangeService = KeyExchangeService();
    var publicKey = keyExchangeService.decodePublicKey(publicKeyText);

    userChat.keyExchange!.remotePublicKey = publicKey;
  }

  Future<void> _confirmKeyExchange(UserChat userChat) async {
    var keyExchangeService = KeyExchangeService();
    var keyExchange = userChat.keyExchange!;

    var keyPair = keyExchange.keyPair!;
    var remotePublicKey = keyExchange.remotePublicKey!;

    var secretKey = await keyExchangeService.generateSharedSecret(keyPair, remotePublicKey);
    userChat.updateSecretKey(secretKey);
    notifyListeners();
  }

  void _sendPublicKey(UserChat userChat, int op) {
    var keyExchangeService = KeyExchangeService();

    User currentUser = userChat.currentUser;
    User recipient = userChat.otherUser;

    var publicKey = userChat.keyExchange!.keyPair!.publicKey;
    String publicKeyText = keyExchangeService.encodePublicKey(publicKey);

    var buffer = ByteDataBuffer.create();
    buffer.writeString(currentUser.username);
    buffer.writeString(recipient.username);
    buffer.writeString(publicKeyText);

    var opProtocol = OpProtocol(op, buffer.data);
    var bytes = opProtocol.createRequest();

    _channel!.sink.add(bytes);
  }

  void _sendKeyExchangeConfirmation(UserChat userChat) {
    User currentUser = userChat.currentUser;
    User recipient = userChat.otherUser;

    var buffer = ByteDataBuffer.create();
    buffer.writeString(currentUser.username);
    buffer.writeString(recipient.username);

    var opProtocol = OpProtocol(opConfirmKeyExchange, buffer.data);
    var bytes = opProtocol.createRequest();

    _channel!.sink.add(bytes);
  }

  UserChat getUserChat(String username) {
    return _userChats[username]!;
  }
}
