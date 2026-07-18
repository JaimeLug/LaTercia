import 'dart:io';

void main() async {
  // Levantamos el servidor en el puerto 8080 aceptando conexiones de la red local
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Escuchando en el puerto ${server.port}... Esperando al ESP32...');

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocket socket = await WebSocketTransformer.upgrade(request);
      print('✅ ¡ESP32 Conectado por Wi-Fi!');

      // Escuchar los mensajes que manda la botonera
      socket.listen((message) {
        print('🖲️ Botón presionado: $message');
      }, onDone: () {
        print('❌ ESP32 Desconectado.');
      });
    } else {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.close();
    }
  }
}
