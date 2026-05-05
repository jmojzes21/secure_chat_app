import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exceptions.dart';
import '../models/user.dart';
import 'backend_context.dart';

class AuthService {
  User? _currentUser;
  String? _userToken;

  User get currentUser => _currentUser!;
  String get userToken => _userToken!;

  Future<void> login(String username, String password) async {
    var url = Uri.https(BackendContext.httpPath, '/login');
    var body = {'username': username, 'password': password};

    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
      encoding: utf8,
    );

    if (response.statusCode != 200) {
      throw AppException('Autentifikacija nije uspjela!');
    }

    var data = jsonDecode(response.body);

    String token = data['token'];
    String name = data['name'];

    User user = User(username: username, name: name);

    _currentUser = user;
    _userToken = token;
  }

  void logout() {
    _currentUser = null;
    _userToken = null;
  }
}
