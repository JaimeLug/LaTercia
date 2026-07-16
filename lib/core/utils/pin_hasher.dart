import 'dart:convert';
import 'package:crypto/crypto.dart';

/// LaTercia stores employee PINs hashed, never in plaintext.
///
/// PINs are short (4 digits, ~10k combinations), so a per-record salt would add
/// little against brute force; the real goal here is that the database never
/// contains a readable PIN. A constant application pepper + SHA-256 keeps the
/// hash deterministic, which means the login lookup stays a simple equality
/// query and the `UNIQUE(pin)` constraint (two employees can't share a PIN)
/// keeps working.
const _pepper = 'latercia::pin::v1';

String hashPin(String pin) =>
    sha256.convert(utf8.encode('$_pepper$pin')).toString();

/// Whether [storedPin] is the hash of the seeded default admin PIN (`0000`).
/// Used to nudge the operator to change it.
bool isDefaultAdminPin(String storedPin) => storedPin == hashPin('0000');
