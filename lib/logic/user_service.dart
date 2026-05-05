import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user.dart';
import 'backend_context.dart';
import 'exceptions.dart';

class UserService {
  Future<List<User>> getAllUsers() async {
    var url = Uri.https(BackendContext.httpPath, '/users');

    var response = await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode != 200) {
      throw AppException('Dohvaćanje korisnika nije uspjelo!');
    }

    var data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => User(username: e['username'], name: e['name'])).toList();
  }

  Future<List<User>> getFriends(String username) async {
    var users = await getAllUsers();
    return users.where((e) => e.username != username).toList();
  }
}
