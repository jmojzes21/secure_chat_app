import 'package:cryptography/cryptography.dart';

class KeyExchange {
  SimpleKeyPairData? keyPair;
  SimplePublicKey? remotePublicKey;

  void destroyPrivateKey() {
    keyPair?.destroy();
  }
}
