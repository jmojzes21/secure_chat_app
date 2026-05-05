class Message {
  bool isReceived;
  String value;

  Message(this.isReceived, this.value);

  factory Message.sent(String value) {
    return Message(false, value);
  }

  factory Message.received(String value) {
    return Message(true, value);
  }

  Map<String, dynamic> toJson() {
    return {'isReceived': isReceived, 'msg': value};
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(json['isReceived'], json['msg']);
  }
}
