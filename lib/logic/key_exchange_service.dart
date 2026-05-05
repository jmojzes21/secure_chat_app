import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'crypto_service.dart';

class KeyExchangeService {
  Future<SimpleKeyPairData> generateKeyPair() async {
    KeyExchangeAlgorithm algorithm = X25519();
    return (await algorithm.newKeyPair()) as SimpleKeyPairData;
  }

  Future<Uint8List> generateSharedSecret(SimpleKeyPairData keyPair, SimplePublicKey remotePublicKey) async {
    KeyExchangeAlgorithm algorithm = X25519();

    SecretKey secretKey = await algorithm.sharedSecretKey(keyPair: keyPair, remotePublicKey: remotePublicKey);
    SecretKeyData secretKeyData = secretKey as SecretKeyData;

    Uint8List keyData = Uint8List.fromList(await secretKeyData.extractBytes());

    var cryptoService = CryptoService();
    Uint8List result = cryptoService.sha256(keyData);

    return result;
  }

  String encodePublicKey(SimplePublicKey publicKey) {
    return base64.encode(publicKey.bytes);
  }

  SimplePublicKey decodePublicKey(String keyText) {
    Uint8List bytes = base64Decode(keyText);
    return SimplePublicKey(bytes, type: KeyPairType.x25519);
  }
}
