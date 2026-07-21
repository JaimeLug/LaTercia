# KDS: comunicación entre procesos y botonera

El POS y el KDS pueden correr como **dos procesos separados del sistema**
(típico: POS en un monitor, Cocina en otro) que comparten el mismo archivo
SQLite. Este documento cubre cómo se sincronizan y cómo entra la botonera
física. Código en `lib/core/services/kds_link.dart`, `kds_server.dart`,
`kds_client.dart` y `kds_button_service.dart`.

## Enlace POS↔KDS por WebSocket

El **proceso POS es el único dueño de la base de datos** y expone un servidor
WebSocket local. La ventana KDS separada se conecta como *viewer*.

- **Bind:** `127.0.0.1` (solo local) en un **puerto efímero** que asigna el SO.
- **Seguridad:** un **token aleatorio por sesión**. El POS escribe `{port, token}`
  en `getApplicationSupportDirectory()/latercia/kds_endpoint.json` (con permisos
  `600` en POSIX para que otros usuarios locales no lean el token) y el KDS lo
  lee para conectarse **sin tocar la base**.
- **Límites defensivos:** máximo 8 clientes, comandos de máximo 4096 bytes
  (los comandos legítimos son de decenas de bytes).
- **Flujo:** el servidor **empuja** el snapshot de pedidos activos; el cliente
  manda comandos de vuelta (marcar listo, recall, cambio de estado).
- **Anti-spam:** el POS emite en cada tick de 2 s aunque nada cambie; el servidor
  no reenvía si el mensaje es idéntico al último, pero sí guarda el snapshot para
  mandárselo de inmediato a un cliente que se acaba de conectar.
- **Fallback:** si el WS no está disponible, el KDS cae al **polling de la base**,
  así nunca se queda sin datos. El cliente reconecta con backoff 1→2→4→10 s.

## Botonera física (ESP32)

Un **servidor aparte** del anterior, para el ESP32 de la cocina (6 botones:
ANTERIOR, SIGUIENTE, PREP, LISTO, RECALL, TIEMPO).

- El ESP32 es **cliente**: se conecta él solo por WebSocket, protocolo de **texto
  plano sin token** (así quedó grabado el firmware ya probado en hardware), y
  manda un string por cada botón.
- **Puerto fijo 8080** para que coincida con el firmware sin reflashearlo.
  Cambiar el puerto en Configuración exige reflashear el ESP32 también.
- Es un mando de **una sola vía**, sin relación con el protocolo POS↔KDS de
  arriba (que sí usa JSON + token en puerto efímero).
- **Rebote mecánico:** un botón puede mandar varios mensajes idénticos en
  milisegundos. Se ignoran los repetidos dentro de una ventana de 180 ms. (El
  stream "crudo" de diagnóstico —Admin → Botonera— sí recibe TODO, rebote
  incluido, para separar un problema de cableado de uno de software.)
- **Mapeo de botones:** literal (el string == el nombre del botón). Hubo un
  intento de "corregir" un supuesto cruce LISTO/TIEMPO en el cableado que causó
  una regresión y se revirtió. Si el cableado real tiene algo cruzado, se
  confirma con el panel de prueba (Admin → Botonera) **antes** de tocar el mapeo.

## Un solo proceso escucha el puerto 8080

Solo el primer proceso que logra bindear el puerto 8080 recibe los eventos del
ESP32. En la práctica siempre gana el **POS** (arranca primero). Una ventana KDS
separada **nunca** logra bindear ese puerto, así que se quedaría sorda — por eso
el POS **retransmite** cada botón que recibe del ESP32 a las ventanas KDS
conectadas por el WS de sincronización.

### El bug de RECALL (por qué se silencia el botón local)

Cuando hay una ventana KDS separada conectada, el KDS **embebido** en el propio
POS deja de procesar la botonera (`kdsButtonStreamProvider` filtra con
`KdsServer.hasClients`). Sin ese filtro, el mismo botón físico se procesaba
**dos veces** (una vez en el KDS embebido, invisible, y otra reenviado a la
ventana externa). Eso rompía RECALL: el segundo `markReady` volvía a leer el
pedido ya en 'listo' y sobrescribía el estado previo guardado para deshacer, así
que recall terminaba revirtiendo 'listo' → 'listo' (nada visible).
