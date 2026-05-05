import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/user.dart';
import '../models/user_chat.dart';
import 'crypto_service.dart';

class ChatRepository {
  String? _userDirPath;

  Future<void> saveUserChat(UserChat userChat) async {
    var currentUser = userChat.currentUser;
    var userDir = await _getUserDir(currentUser.username);
    var chatPath = path.join(userDir, 'chat_${userChat.otherUser.username}');

    var cryptoService = CryptoService();

    var jsonText = jsonEncode(userChat.toJson());

    Uint8List toEncrypt = utf8.encode(jsonText);
    var key = await _getKey();
    var iv = cryptoService.generateAesIv();

    Uint8List encrypted = cryptoService.aesGcmEncrypt(toEncrypt, key, iv);

    var chatFile = File(chatPath);
    await chatFile.writeAsBytes(encrypted, flush: true);
  }

  Future<List<UserChat>> loadUserChats(User currentUser) async {
    List<UserChat> result = [];

    var userDir = Directory(await _getUserDir(currentUser.username));
    var files = await userDir.list().toList();

    for (var file in files) {
      if (file is File) {
        String name = path.basename(file.path);
        if (name.startsWith('chat_')) {
          try {
            var userChat = await _loadUserChat(currentUser, file);
            result.add(userChat);
          } catch (e) {
            log(e.toString());
          }
        }
      }
    }

    return result;
  }

  Future<UserChat> _loadUserChat(User currentUser, File chatFile) async {
    var cryptoService = CryptoService();

    Uint8List encrypted = await chatFile.readAsBytes();
    var key = await _getKey();

    Uint8List decrypted = cryptoService.aesGcmDecrypt(encrypted, key);

    String jsonText = utf8.decode(decrypted);
    var json = jsonDecode(jsonText);

    UserChat userChat = UserChat.fromJson(json, currentUser);
    return userChat;
  }

  Future<Uint8List> _getKey() async {
    var secureStorage = FlutterSecureStorage();
    String? aesKeyText = await secureStorage.read(key: 'aes_key');

    if (aesKeyText == null) {
      var cryptoService = CryptoService();
      Uint8List aesKey = cryptoService.generateAesKey256();

      aesKeyText = base64.encode(aesKey);
      await secureStorage.write(key: 'aes_key', value: aesKeyText);

      return aesKey;
    }

    Uint8List aesKey = base64.decode(aesKeyText);
    return aesKey;
  }

  Future<String> _getUserDir(String username) async {
    if (_userDirPath == null) {
      var appDir = await getApplicationSupportDirectory();
      _userDirPath = path.join(appDir.path, username);

      var userDir = Directory(_userDirPath!);
      await userDir.create();
    }

    return _userDirPath!;
  }
}
