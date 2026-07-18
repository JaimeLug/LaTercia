import 'dart:io';

/// IP(s) locales de esta máquina en la red — usado por la botonera (para saber
/// qué grabar en el firmware del ESP32) y por la pantalla de Quiosco (info del
/// equipo). Best-effort: lista vacía si no se puede enumerar, nunca lanza.
Future<List<String>> localIpAddresses() async {
  try {
    final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4, includeLoopback: false);
    return [
      for (final i in interfaces)
        for (final a in i.addresses) a.address,
    ];
  } catch (_) {
    return const [];
  }
}
