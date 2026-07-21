import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database.dart';
import '../models/order_with_items.dart';

// Protocolo compartido del enlace POS↔KDS por WebSocket. `docs/kds-conexion.md`.

const kdsWsPath = '/kds';

/// Archivo endpoint `{port, token}` que el POS publica y el KDS lee.
/// `docs/kds-conexion.md` §"Enlace POS↔KDS".
Future<File> kdsEndpointFile() async {
  final appDir = await getApplicationSupportDirectory();
  final dir = Directory(p.join(appDir.path, 'latercia'));
  await dir.create(recursive: true);
  return File(p.join(dir.path, 'kds_endpoint.json'));
}

Future<void> writeKdsEndpoint(int port, String token) async {
  final f = await kdsEndpointFile();
  await f.writeAsString(jsonEncode({'port': port, 'token': token}));
  // Restringe el archivo al dueño (600) en POSIX para que otros usuarios no
  // lean el token. En Windows se omite (best-effort). docs/kds-conexion.md.
  if (Platform.isLinux || Platform.isMacOS) {
    try {
      await Process.run('chmod', ['600', f.path]);
    } catch (_) {/* best-effort */}
  }
}

Future<({int port, String token})?> readKdsEndpoint() async {
  try {
    final f = await kdsEndpointFile();
    if (!await f.exists()) return null;
    final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    final port = m['port'];
    final token = m['token'];
    if (port is! int || token is! String) return null;
    return (port: port, token: token);
  } catch (_) {
    return null;
  }
}

// ─── Serialización ───────────────────────────────────────────────────────────

/// Mensaje servidor→cliente: snapshot de pedidos activos + si hay recall
/// disponible. Usa el `toJson`/`fromJson` que genera drift para cada fila.
String encodeOrdersMessage(List<OrderWithItems> orders, bool canRecall) {
  return jsonEncode({
    'type': 'orders',
    'canRecall': canRecall,
    'data': [
      for (final o in orders)
        {
          'order': o.order.toJson(),
          'items': [for (final i in o.items) i.toJson()],
        },
    ],
  });
}

List<OrderWithItems> decodeOrders(Map<String, dynamic> msg) {
  final data = (msg['data'] as List).cast<Map<String, dynamic>>();
  return [
    for (final e in data)
      OrderWithItems(
        order: Order.fromJson((e['order'] as Map).cast<String, dynamic>()),
        items: [
          for (final i in (e['items'] as List))
            OrderItem.fromJson((i as Map).cast<String, dynamic>()),
        ],
      ),
  ];
}

/// Mensaje cliente→servidor: un comando de la cocina.
String encodeCommand(String cmd, {int? orderId, String? status}) {
  return jsonEncode({
    'type': 'cmd',
    'cmd': cmd,
    if (orderId != null) 'orderId': orderId,
    if (status != null) 'status': status,
  });
}
