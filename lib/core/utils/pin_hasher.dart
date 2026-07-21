import 'dart:convert';
import 'package:crypto/crypto.dart';

/// PINs hasheados (pepper + SHA-256), nunca en texto plano. `docs/seguridad.md`.
const _pepper = 'latercia::pin::v1';

String hashPin(String pin) =>
    sha256.convert(utf8.encode('$_pepper$pin')).toString();

/// Si [storedPin] es el hash del admin sembrado por defecto (`0000`).
bool isDefaultAdminPin(String storedPin) => storedPin == hashPin('0000');
