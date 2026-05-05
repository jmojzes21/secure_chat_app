import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'exceptions.dart';

class CryptoService {
  Uint8List generateAesKey256() {
    return generateRandomBytes(32);
  }

  Uint8List generateAesIv() {
    return generateRandomBytes(16);
  }

  String aesGcmEncryptText(String inputText, Uint8List key, Uint8List iv) {
    Uint8List toEncrypt = utf8.encode(inputText);
    Uint8List encrypted = aesGcmEncrypt(toEncrypt, key, iv);
    return base64.encode(encrypted);
  }

  String aesGcmDecryptText(String inputBase64, Uint8List key) {
    Uint8List encrypted = base64.decode(inputBase64);
    Uint8List decrypted = aesGcmDecrypt(encrypted, key);
    return utf8.decode(decrypted);
  }

  Uint8List aesGcmEncrypt(Uint8List input, Uint8List key, Uint8List iv) {
    Uint8List encrypted = _aesGcmEncrypt(input, key, iv);
    List<int> output = [...iv, ...encrypted];
    return Uint8List.fromList(output);
  }

  Uint8List aesGcmDecrypt(Uint8List input, Uint8List key) {
    if (input.length < 32) {
      throw AppException('Dekriptiranje nije moguće!');
    }

    Uint8List iv = input.sublist(0, 16);
    Uint8List encrypted = input.sublist(16);

    Uint8List decrypted = _aesGcmDecrypt(encrypted, key, iv);
    return decrypted;
  }

  Uint8List sha256(Uint8List input) {
    var d = SHA256Digest();
    return d.process(input);
  }

  Uint8List _aesGcmEncrypt(Uint8List input, Uint8List key, Uint8List iv) {
    var cipher = PaddedBlockCipher('AES/GCM/PKCS7');
    cipher.init(true, PaddedBlockCipherParameters(ParametersWithIV(KeyParameter(key), iv), null));

    return cipher.process(input);
  }

  Uint8List _aesGcmDecrypt(Uint8List input, Uint8List key, Uint8List iv) {
    var cipher = PaddedBlockCipher('AES/GCM/PKCS7');
    cipher.init(false, PaddedBlockCipherParameters(ParametersWithIV(KeyParameter(key), iv), null));

    if (input.length % cipher.blockSize != 0) {
      throw Exception('Dekriptiranje nije moguće!');
    }

    try {
      return cipher.process(input);
    } on Error catch (_) {
      throw Exception('AES dekriptiranje nije uspjelo');
    }
  }

  Uint8List generateRandomBytes(int count) {
    var secureRandom = FortunaRandom();

    var random = math.Random.secure();
    var seed = List.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seed)));

    var randomBytes = secureRandom.nextBytes(count);
    return randomBytes;
  }
}
