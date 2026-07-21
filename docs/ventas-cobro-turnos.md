# Ventas, cobro, reembolsos y turnos

Dominio del dinero. Todo el cálculo monetario vive en servicios (no en la UI)
para poder probarlo aislado y para que las operaciones sean **atómicas**
(transacción de drift: o todo se guarda, o nada). Código en
`lib/core/services/checkout_service.dart`, `refund_service.dart` y
`shift_service.dart`.

## Cobro atómico (`CheckoutService`)

Antes, cobrar eran tres o cuatro escrituras separadas pegadas por el llamador
(crear orden → insertar pago → marcar pagada → sumar visita al cliente), cada
una con su propio commit. Un fallo entre dos de ellas podía dejar una orden sin
pago, un pago sobre una orden a medio construir, o inventario descontado por una
venta que nunca se cobró.

- **`checkout`** funde todo eso en **una** `db.transaction`: si algo lanza a
  media operación, drift revierte todo (no sobrevive ni la orden, ni los items,
  ni el movimiento de inventario, ni el pago, ni la actualización del cliente).
- **`chargeExistingOrder`** cobra una orden **ya creada** y enviada a cocina sin
  pagar (flujo de mesa "pagar al final"). NO crea la orden, sus items ni los
  movimientos de inventario (eso ya pasó al enviar a cocina); solo registra el
  pago contra el turno abierto y marca la orden pagada. Los montos de la orden ya
  están fijados desde que se armó, así que nada se recalcula aquí.

### Pagos y pagos mixtos (`PaymentDraft`)

Un `PaymentDraft` es un pago (parcial o total) que compone el cobro. Para pagos
mixtos, el modal produce varios; para el cobro simple, uno solo.
`amountTendered`/`changeGiven` son lo entregado y el cambio (el cambio solo
aparece en el tramo en efectivo que cierra el saldo). `tipAmount` es la propina
asociada a ese pago.

**Defensa en profundidad:** lo aplicado por los pagos (`entregado − cambio`) debe
cubrir el total antes de marcar la orden pagada. La propina infla lo aplicado por
encima del total, así que la comparación es `≥`.

### Regla: pagar NO entrega la orden

Pagar por sí solo no marca la orden como entregada (eso la ocultaría de la
cocina). La orden solo se completa aquí si la cocina **ya** la había marcado
'listo' antes de que el cajero cobrara; si no, sigue visible en el KDS hasta que
la cocina la termine. (Mismo criterio que `OrdersNotifier.markPaid`.)

### Número de orden legible

La orden se inserta con un placeholder único temporal (`tmp-<uuid>`) y luego se
deriva el número legible del `id` autoincremental. Esto evita una carrera
`max(id)+1` entre los procesos POS y KDS. (Mismo patrón que
`OrdersNotifier.sendToKitchen`.)

### Auditoría atómica

La venta se registra en `audit_log` **dentro de la misma transacción**: si algo
revierte, la fila de auditoría tampoco queda.

## Reembolsos (`RefundService`)

Un reembolso **nunca** edita la venta original: registra un contra-movimiento
**inmutable** en `refunds`.

- Solo sobre una orden **pagada**; el monto debe ser > 0.
- **Tope:** no se puede devolver más de lo pagado menos lo ya reembolsado. Se
  valida en el servicio (no solo en la UI) por tratarse de dinero.
- Siempre pasa por **supervisor** (el llamador ya obtuvo el PIN y pasa
  `supervisorId` — ver `docs/permisos-y-auditoria.md`).
- **Restock opcional:** devuelve el stock de la línea indicada o de toda la
  orden.
- Queda ligado al **turno abierto** para que el corte Z lo reste, y se audita.

## Turnos y arqueo (`ShiftService`)

Un solo turno abierto a la vez, en todo el sistema. Todo el cálculo de dinero
(depósitos, retiros, ventas en efectivo, esperado vs. contado) vive aquí para que
el **Corte X** (solo lectura, a media jornada) y el **Corte Z** (resultado de
cerrar) compartan una sola implementación.

### Arqueo (`ShiftSummary`)

Nada del arqueo se persiste más allá de lo que `Shift` ya guarda: se deriva a
demanda desde `Payments`/`CashMovements`/`Orders`.

- **`cashSales`**: solo ventas en efectivo, neto del cambio dado.
- **`expectedCash`** = `startingCash + cashSales + deposits − withdrawals −
  refundsTotal`.
- **`countedCash`**: solo se conoce al cerrar (null en un Corte X).
- **`difference`** = `countedCash − expectedCash`.
- **`tipsTotal`**: suma de propinas del turno. Va como línea aparte (no es
  venta). El efectivo de la propina **sí** está físicamente en la gaveta, por eso
  `cashSales`/`expectedCash` ya lo incluyen; esto es solo para saber cuánto de lo
  cobrado fue propina.
- **`refundsTotal`**: se resta de `expectedCash` porque el efectivo devuelto sale
  físicamente de la gaveta.

### Abrir / cerrar

- **Abrir:** lanza si ya hay uno abierto (guarda del invariante real; el chequeo
  de la UI puede tener una carrera).
- **Cerrar:** asigna el siguiente `zNumber` consecutivo y sella
  `endingCash`/`totalSales`, todo en una transacción. El *gating* de permiso
  (`corteZ`, `movimientoCaja`) ocurre en el punto de llamada antes de invocar
  estos métodos.
