import 'dart:math';

import 'package:encrypt/encrypt.dart' as EncryptPack;
import 'package:crypto/crypto.dart' as CryptoPack;
import 'dart:convert' as ConvertPack;
import 'dart:developer';

class Crypto {
  static String dfixed(String payload) {
    String strPwd = "6P8yHVfeZ5JKaXQ6AyaBge";
    String strIv = 'cHaa5y7pQF5uqA2N';
    var iv = CryptoPack.sha256
        .convert(ConvertPack.utf8.encode(strIv))
        .toString()
        .substring(0, 16); // Consider the first 16 bytes of all 64 bytes
    var key = CryptoPack.sha256
        .convert(ConvertPack.utf8.encode(strPwd))
        .toString()
        .substring(0, 32); // Consider the first 32 bytes of all 64 bytes
    EncryptPack.IV ivObj = EncryptPack.IV.fromUtf8(iv);
    EncryptPack.Key keyObj = EncryptPack.Key.fromUtf8(key);
    final encrypter = EncryptPack.Encrypter(EncryptPack.AES(keyObj,
        mode: EncryptPack.AESMode.cbc)); // Apply CBC mode
    String firstBase64Decoding = String.fromCharCodes(
        ConvertPack.base64.decode(payload)); // First Base64 decoding
    final decrypted = encrypter.decrypt(
        EncryptPack.Encrypted.fromBase64(firstBase64Decoding),
        iv: ivObj); // Second Base64 decoding (during decryption)
    return decrypted;
  }

  String cfixed(String payload) {
    String strPwd = "6P8yHVfeZ5JKaXQ6AyaBge";
    String strIv = 'cHaa5y7pQF5uqA2N';
    var iv = CryptoPack.sha256
        .convert(ConvertPack.utf8.encode(strIv))
        .toString()
        .substring(0, 16); // Consider the first 16 bytes of all 64 bytes
    var key = CryptoPack.sha256
        .convert(ConvertPack.utf8.encode(strPwd))
        .toString()
        .substring(0, 32); // Consider the first 32 bytes of all 64 bytes
    EncryptPack.IV ivObj = EncryptPack.IV.fromUtf8(iv);
    EncryptPack.Key keyObj = EncryptPack.Key.fromUtf8(key);

    final encrypter = EncryptPack.Encrypter(
        EncryptPack.AES(keyObj, mode: EncryptPack.AESMode.cbc));

    final encrypted = encrypter.encrypt(payload.toString(), iv: ivObj);
    inspect(encrypted);
    return ConvertPack.base64.encode(ConvertPack.utf8.encode(encrypted.base64));
  }

  static String d(String payload) {
    String strIv =
        payload.substring(0, 5) + payload.substring(payload.length - 5);
    String strPwd = '4afa838c38';

    int len = int.parse(payload.substring(5, 9));
    payload = payload.substring(9, 9 + len);

    //"bea4437dbc";

    var iv = CryptoPack.sha256
        .convert(ConvertPack.utf8.encode(strIv))
        .toString()
        .substring(0, 16); // Consider the first 16 bytes of all 64 bytes
    var key = CryptoPack.sha256
        .convert(ConvertPack.utf8.encode(strPwd))
        .toString()
        .substring(0, 32); // Consider the first 32 bytes of all 64 bytes
    EncryptPack.IV ivObj = EncryptPack.IV.fromUtf8(iv);
    EncryptPack.Key keyObj = EncryptPack.Key.fromUtf8(key);
    final encrypter = EncryptPack.Encrypter(EncryptPack.AES(keyObj,
        mode: EncryptPack.AESMode.cbc)); // Apply CBC mode
    String firstBase64Decoding = String.fromCharCodes(
        ConvertPack.base64.decode(payload)); // First Base64 decoding
    final decrypted = encrypter.decrypt(
        EncryptPack.Encrypted.fromBase64(firstBase64Decoding),
        iv: ivObj); // Second Base64 decoding (during decryption)
    return decrypted;
  }

  static String c(String payload) {
    String strPwd = "4afa838c38";

    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    Random rnd = Random();

    String strIv = String.fromCharCodes(Iterable.generate(
        10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

    var iv = CryptoPack.sha256
        .convert(ConvertPack.utf8.encode(strIv))
        .toString()
        .substring(0, 16); // Consider the first 16 bytes of all 64 bytes
    var key = CryptoPack.sha256
        .convert(ConvertPack.utf8.encode(strPwd))
        .toString()
        .substring(0, 32); // Consider the first 32 bytes of all 64 bytes
    EncryptPack.IV ivObj = EncryptPack.IV.fromUtf8(iv);
    EncryptPack.Key keyObj = EncryptPack.Key.fromUtf8(key);

    final encrypter = EncryptPack.Encrypter(
        EncryptPack.AES(keyObj, mode: EncryptPack.AESMode.cbc));

    final encrypted = encrypter.encrypt(payload.toString(), iv: ivObj);
    String r =
        ConvertPack.base64.encode(ConvertPack.utf8.encode(encrypted.base64));
    int l = r.length;
    String rfinal = strIv.substring(0, 5) +
        l.toString().padLeft(4, '0') +
        r +
        strIv.substring(5);

    return rfinal;
  }
}
