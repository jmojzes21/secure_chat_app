class User {
  String username;
  String name;

  User({required this.username, required this.name});

  Map<String, dynamic> toJson() {
    return {'username': username, 'name': name};
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(username: json['username'], name: json['name']);
  }
}
