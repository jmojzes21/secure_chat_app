import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class ByteDataBuffer {
  late Uint8List _buffer;
  late ByteData _byteData;

  int position = 0;
  Endian endian = Endian.big;

  ByteDataBuffer(Uint8List buffer) {
    _buffer = buffer;
    _byteData = ByteData.view(_buffer.buffer);
  }

  ByteDataBuffer.create([int initCapacity = 200]) {
    _buffer = Uint8List(initCapacity);
    _byteData = ByteData.view(_buffer.buffer);
  }

  int readUint16() {
    _checkRead(2);
    int value = _byteData.getUint16(position, endian);
    position += 2;
    return value;
  }

  void writeUint16(int value) {
    _checkWrite(2);
    _byteData.setUint16(position, value, endian);
    position += 2;
  }

  String readString() {
    int len = readUint16();

    _checkRead(len);
    Uint8List bytes = _buffer.sublist(position, position + len);
    position += len;

    return utf8.decode(bytes);
  }

  void writeString(String value) {
    Uint8List bytes = utf8.encode(value);
    int len = bytes.length;

    writeUint16(len);

    _checkWrite(len);
    _buffer.setAll(position, bytes);
    position += len;
  }

  Uint8List get data => _buffer.sublist(0, position);

  void _checkRead(int length) {
    if (position + length > _buffer.length) {
      throw Exception('Position out of bounds, position: ${position + length}, length: ${_buffer.length}');
    }
  }

  void _checkWrite(int length) {
    int requiredSize = position + length;

    if (requiredSize > _buffer.length) {
      int newCapacity = math.max(_buffer.length * 2, requiredSize);

      Uint8List newBuffer = Uint8List(newCapacity);
      newBuffer.setAll(0, _buffer);

      _buffer = newBuffer;
      _byteData = ByteData.view(_buffer.buffer);
    }
  }
}
