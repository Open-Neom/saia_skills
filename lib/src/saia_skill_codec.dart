import 'dart:convert';

/// Contenedor codificado y opcionalmente cifrado de una habilidad SAIA.
class SaiaSkillPackage {
  /// Identificador canónico de la habilidad.
  final String id;

  /// Categoría de la habilidad.
  final String category;

  /// Idioma original del contenido empaquetado.
  final String language;

  /// Payload codificado en Base64.
  final String payload;

  /// Suma de verificación Adler-32 sin signo (`0..4294967295`) para integridad.
  final int checksum;

  /// Indica si el payload requiere clave de desencriptación.
  final bool isEncrypted;

  /// Crea un paquete codificado de habilidad.
  const SaiaSkillPackage({
    required this.id,
    required this.category,
    required this.language,
    required this.payload,
    required this.checksum,
    this.isEncrypted = false,
  });

  static int _toUint32Safe(Object? raw) {
    if (raw is num) {
      if (!raw.isFinite) return 0;
      if (raw >= 0 && raw <= 0xFFFFFFFF) {
        return raw is int ? raw : raw.truncate();
      }
      final mod = raw.remainder(4294967296.0);
      final normalized = mod < 0 ? mod + 4294967296.0 : mod;
      return normalized.isFinite ? normalized.truncate() : 0;
    }
    if (raw is String) {
      final parsed = int.tryParse(raw.trim());
      if (parsed != null) return _toUint32Safe(parsed);
    }
    return 0;
  }

  /// Convierte el paquete a Map serializable a JSON.
  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'language': language,
        'payload': payload,
        'checksum': _toUint32Safe(checksum),
        'isEncrypted': isEncrypted,
      };

  /// Construye un paquete desde un Map deserializado de JSON o Hive.
  factory SaiaSkillPackage.fromMap(Map<Object?, Object?> map) {
    return SaiaSkillPackage(
      id: map['id']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      language: map['language']?.toString() ?? 'es',
      payload: map['payload']?.toString() ?? '',
      checksum: _toUint32Safe(map['checksum']),
      isEncrypted: map['isEncrypted'] == true,
    );
  }
}

/// Códec para empaquetar, comprimir y opcionalmente cifrar habilidades.
///
/// Opera de manera 100% pura en Dart, compatible con Web, Desktop y Mobile
/// sin requerir dependencias externas pesadas.
class SaiaSkillCodec {
  SaiaSkillCodec._();

  /// Hard ceiling on decoded skill content (4 MiB) and Base64 payload (~5.5 MiB)
  /// to prevent OOM on corrupted or adversarial packages.
  static const int maxDecodedBytes = 4 * 1024 * 1024;
  static const int maxEncodedPayloadChars = 6 * 1024 * 1024;

  /// Calcula una suma de verificación rápida (Adler-32) sin signo (`0..4294967295`).
  ///
  /// Usa `(b * 65536) + a` en lugar de `(b << 16) | a` para evitar el wraparound
  /// con signo de 32 bits en `dart2js` cuando `b >= 32768`, garantizando paridad
  /// exacta entre Desktop/Mobile VM y Chrome Web.
  static int computeChecksum(List<int> bytes) {
    var a = 1;
    var b = 0;
    const mod = 65521;
    for (final byte in bytes) {
      a = (a + (byte & 0xFF)) % mod;
      b = (b + a) % mod;
    }
    return (b * 65536) + a;
  }

  /// Aplica cifrado/descifrado simétrico reversible mediante rotación de flujo.
  static List<int> _applyCipher(List<int> data, List<int> key) {
    if (key.isEmpty) return data;
    final result = List<int>.filled(data.length, 0);
    for (var i = 0; i < data.length; i++) {
      result[i] = (data[i] & 0xFF) ^ (key[i % key.length] & 0xFF);
    }
    return result;
  }

  /// Codifica y opcionalmente cifra el contenido de una habilidad.
  static SaiaSkillPackage encode({
    required String id,
    required String category,
    required String language,
    required String markdownContent,
    List<int>? encryptionKey,
  }) {
    final rawBytes = utf8.encode(markdownContent);
    if (rawBytes.length > maxDecodedBytes) {
      throw StateError(
        'El contenido de la habilidad "${id.trim()}" excede el límite de $maxDecodedBytes bytes.',
      );
    }
    final checksum = computeChecksum(rawBytes);

    final processedBytes = encryptionKey != null && encryptionKey.isNotEmpty
        ? _applyCipher(rawBytes, encryptionKey)
        : rawBytes;

    final base64Payload = base64.encode(processedBytes);

    return SaiaSkillPackage(
      id: id,
      category: category,
      language: language,
      payload: base64Payload,
      checksum: checksum,
      isEncrypted: encryptionKey != null && encryptionKey.isNotEmpty,
    );
  }

  /// Decodifica y opcionalmente descifra el paquete de una habilidad.
  ///
  /// Lanza [StateError] si la suma de verificación falla o falta la clave.
  static String decode(
    SaiaSkillPackage package, {
    List<int>? decryptionKey,
  }) {
    if (package.payload.length > maxEncodedPayloadChars) {
      throw StateError(
        'El payload de la habilidad "${package.id}" excede el tamaño máximo permitido.',
      );
    }
    if (package.isEncrypted &&
        (decryptionKey == null || decryptionKey.isEmpty)) {
      throw StateError(
        'El paquete de la habilidad "${package.id}" está cifrado y requiere una clave.',
      );
    }

    final cipherBytes = _decodeBase64Safe(package);
    if (cipherBytes.length > maxDecodedBytes) {
      throw StateError(
        'El paquete decodificado de "${package.id}" excede $maxDecodedBytes bytes.',
      );
    }

    final rawBytes = package.isEncrypted
        ? _applyCipher(
            cipherBytes,
            decryptionKey ?? const [],
          )
        : cipherBytes;

    final computed = computeChecksum(rawBytes);
    final expected = SaiaSkillPackage._toUint32Safe(package.checksum);
    if (computed != expected) {
      throw StateError(
        'Fallo de integridad en la habilidad "${package.id}": checksum incorrecto.',
      );
    }

    try {
      return utf8.decode(rawBytes);
    } on FormatException {
      throw StateError(
        'Fallo de integridad en la habilidad "${package.id}": contenido UTF-8 inválido.',
      );
    }
  }

  static List<int> _decodeBase64Safe(SaiaSkillPackage package) {
    try {
      return base64.decode(package.payload);
    } on FormatException {
      throw StateError(
        'Fallo de integridad en la habilidad "${package.id}": Base64 inválido.',
      );
    }
  }
}
