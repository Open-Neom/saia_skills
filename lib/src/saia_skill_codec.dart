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

  /// Suma de verificación simple para integridad.
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

  /// Convierte el paquete a Map serializable a JSON.
  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'language': language,
        'payload': payload,
        'checksum': checksum,
        'isEncrypted': isEncrypted,
      };

  /// Construye un paquete desde un Map deserializado de JSON.
  factory SaiaSkillPackage.fromMap(Map<String, dynamic> map) {
    return SaiaSkillPackage(
      id: map['id'] as String? ?? '',
      category: map['category'] as String? ?? '',
      language: map['language'] as String? ?? 'es',
      payload: map['payload'] as String? ?? '',
      checksum: (map['checksum'] as num?)?.toInt() ?? 0,
      isEncrypted: map['isEncrypted'] as bool? ?? false,
    );
  }
}

/// Códec para empaquetar, comprimir y opcionalmente cifrar habilidades.
///
/// Opera de manera 100% pura en Dart, compatible con Web, Desktop y Mobile
/// sin requerir dependencias externas pesadas.
class SaiaSkillCodec {
  SaiaSkillCodec._();

  /// Calcula una suma de verificación rápida (Adler-32) para validar integridad.
  static int computeChecksum(List<int> bytes) {
    var a = 1;
    var b = 0;
    const mod = 65521;
    for (final byte in bytes) {
      a = (a + byte) % mod;
      b = (b + a) % mod;
    }
    return (b << 16) | a;
  }

  /// Aplica cifrado/descifrado simétrico reversible mediante rotación de flujo.
  static List<int> _applyCipher(List<int> data, List<int> key) {
    if (key.isEmpty) return data;
    final result = List<int>.filled(data.length, 0);
    for (var i = 0; i < data.length; i++) {
      result[i] = data[i] ^ key[i % key.length];
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
    final cipherBytes = base64.decode(package.payload);

    final rawBytes = package.isEncrypted
        ? _applyCipher(
            cipherBytes,
            decryptionKey ?? const [],
          )
        : cipherBytes;

    final computed = computeChecksum(rawBytes);
    if (computed != package.checksum) {
      if (package.isEncrypted &&
          (decryptionKey == null || decryptionKey.isEmpty)) {
        throw StateError(
            'El paquete de la habilidad "${package.id}" está cifrado y requiere una clave.');
      }
      throw StateError(
          'Fallo de integridad en la habilidad "${package.id}": checksum incorrecto.');
    }

    return utf8.decode(rawBytes);
  }
}
