import 'dart:typed_data';

import 'byte_data_buffer.dart';

class OpProtocol {
  final int op;
  final Uint8List payload;

  OpProtocol(this.op, this.payload);

  Uint8List createRequest() {
    Uint8List data = Uint8List(4 + payload.length);

    var byteData = ByteData.view(data.buffer);
    byteData.setUint16(0, op, Endian.big);
    byteData.setUint16(2, payload.length, Endian.big);
    data.setAll(4, payload);

    return data;
  }

  factory OpProtocol.decode(Uint8List data) {
    var buffer = ByteDataBuffer(data);
    int op = buffer.readUint16();
    int size = buffer.readUint16();
    Uint8List payload = data.sublist(4, 4 + size);

    return OpProtocol(op, payload);
  }
}
