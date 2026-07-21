# Ciclo de vida de las órdenes

`OrdersNotifier` (`lib/core/providers/orders_provider.dart`) mantiene la lista de
órdenes activas y su ciclo de vida (enviar a cocina → preparar → listo → cobrar
→ entregado / cancelado). Se relaciona con la comunicación POS↔KDS
(`docs/kds-conexion.md`) y las ventas (`docs/ventas-cobro-turnos.md`).

## Sincronización POS↔KDS

POS y KDS pueden ser dos procesos que comparten el mismo archivo SQLite. Los
streams de drift solo disparan para escrituras del **mismo** proceso, así que:

- **Polling:** cada 2 s se releen las órdenes activas de la base, para que ambos
  procesos se mantengan en sync.
- **Modo cliente WS** (solo en la ventana KDS separada): mientras el `KdsClient`
  esté conectado, el estado lo dictan los snapshots del servidor y los comandos
  (listo/recall/estado) viajan por WebSocket al POS —dueño de la base— en vez de
  escribir aquí. Si cae la conexión, se vuelve al polling de inmediato.

## Número de orden

Se inserta con un placeholder único temporal (`tmp-<uuid>`) y luego se deriva el
número legible del `id` autoincremental. SQLite garantiza que ese id es único, lo
que evita la carrera `max(id)+1` que podía producir números duplicados con POS y
KDS escribiendo a la vez.

## Enviar a cocina (`sendToKitchen`)

Todo (orden + items + inventario) es **all-or-nothing** en una transacción: un
fallo a media operación solía dejar órdenes sin items, o stock descontado por una
orden que nunca se creó.

## Marcar listo y "entregado" (`markReady`)

Una orden está totalmente terminada (**entregada**) solo cuando está **lista Y
pagada**:

- Si ya está pagada, terminarla en cocina la completa y libera su mesa.
- Si no, se queda en 'listo' para que el cajero aún pueda cobrarla (flujo de mesa
  / pagar-al-final).

## Recall (deshacer "listo")

`recallLastReady` deshace el `markReady` más reciente si ocurrió dentro de la
**ventana de 60 s** (`recallWindow`). Restaura el estado que la orden tenía
antes, limpia el timestamp de completada, y —si marcarla lista la había entregado
y liberado una mesa— vuelve a ocupar esa mesa.

- El "último listo" se guarda **en memoria** y es **local al proceso** que lo
  marcó: solo ese KDS puede deshacer su propia acción. (En modo WS, el POS reporta
  `canRecall`.)

## Cobrar (`markPaid`)

Pagar **no** fuerza la orden a 'entregado' (eso la ocultaría del KDS si el cajero
cobra antes de que la comida esté hecha). Solo se entrega aquí si la cocina ya la
terminó (status 'listo'); si no, sigue visible en el KDS. (Mismo criterio que
`chargeExistingOrder` en `docs/ventas-cobro-turnos.md`.)

## Cancelar orden (`cancelOrder`)

Devuelve a inventario el stock reservado de cada item rastreado (se descontó al
enviar a cocina, así que cancelar debe reponerlo o el inventario se desfasa
permanentemente), marca la orden cancelada, libera la mesa y audita.

## Anular una línea (`voidOrderItem`)

Anula **una** línea de una orden aún **no pagada**: marca el item como cancelado,
devuelve su stock y **reescala** los montos de la orden proporcionalmente al
subtotal restante. Exacto para descuentos porcentuales e IVA (lineales en el
subtotal); aproximado si hubo un descuento fijo (poco común en cafetería). Anular
una línea ya pagada es un **reembolso**, no esto.
