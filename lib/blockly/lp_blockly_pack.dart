import 'dart:convert';
import 'dart:typed_data';

/// Blockly 资源包（`.lpk`）：安装包内单文件分发，运行时解密解压，避免暴露 JS 源码目录。
abstract final class LpBlocklyPack {
  static const String fileName = 'visualprogram.lpk';
  static const String assetPath = 'assets/blockly/$fileName';

  static const List<int> _magic = [0x4C, 0x50, 0x52, 0x4F, 0x42, 0x54, 0x01];

  /// 将 zip 字节流编码为 `.lpk`。
  static Uint8List encode(Uint8List zipBytes) {
    final key = _deriveKey();
    final body = Uint8List(zipBytes.length);
    for (var i = 0; i < zipBytes.length; i++) {
      body[i] = zipBytes[i] ^ key[i % key.length];
    }

    final out = BytesBuilder(copy: false);
    out.add(_magic);
    out.add(_u32le(body.length));
    out.add(body);
    return out.toBytes();
  }

  /// 将 `.lpk` 解码为 zip 字节流。
  static Uint8List decode(Uint8List lpkBytes) {
    if (lpkBytes.length < _magic.length + 4) {
      throw FormatException('LPK 文件过短');
    }
    for (var i = 0; i < _magic.length; i++) {
      if (lpkBytes[i] != _magic[i]) {
        throw FormatException('LPK 魔数不匹配');
      }
    }
    final length = _readU32le(lpkBytes, _magic.length);
    final bodyStart = _magic.length + 4;
    if (bodyStart + length != lpkBytes.length) {
      throw FormatException('LPK 长度字段无效');
    }
    final key = _deriveKey();
    final zip = Uint8List(length);
    for (var i = 0; i < length; i++) {
      zip[i] = lpkBytes[bodyStart + i] ^ key[i % key.length];
    }
    return zip;
  }

  static Uint8List _deriveKey() {
    const parts = ['Lingpeng', 'Smart', 'Blockly', 'Pack', '2026'];
    final raw = utf8.encode(parts.join());
    final key = Uint8List(32);
    for (var i = 0; i < key.length; i++) {
      key[i] = raw[i % raw.length] ^ (0x5A + (i * 17));
    }
    return key;
  }

  static List<int> _u32le(int value) => [
        value & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
      ];

  static int _readU32le(Uint8List bytes, int offset) =>
      bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}
