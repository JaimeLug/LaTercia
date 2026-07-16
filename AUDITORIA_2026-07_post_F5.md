# Auditoría Técnica — La Tercia POS + KDS (post Fase 5)

**Fecha:** 2026-07-15 · **Alcance:** todo el código tras Fases 1–5 (integridad, caja/auditoría, hardware/impresión, ventas avanzadas, escalabilidad/WS).
**Base:** ~32k líneas / 112 archivos Dart · 104 tests verdes · `flutter analyze` limpio · build Windows OK.
**Auditoría previa:** [AUDITORIA_2026-07.md](AUDITORIA_2026-07.md) (C1–C6, I1–I9 resueltos).

---

## Resumen ejecutivo

El sistema está **sólido y en buen estado**: cobro atómico en capa de servicio, auditoría append-only, WAL + `busy_timeout`, migraciones ordenadas (una por fase, v5), motor de IVA por línea testeado, WS con fallback a BD, backups con checkpoint. La deuda es acotada y localizada, sobre todo en **integridad referencial de la BD** y **validaciones defensivas de dinero** (reembolsos/pagos). Ningún hallazgo bloquea el uso actual, pero **A1–A3 conviene cerrarlos antes de la Fase 6 / producción** porque son de integridad financiera.

Total: **3 altos · 5 medios · 4 bajos/notas.**

---

## Hallazgos ALTOS

### A1 — `PRAGMA foreign_keys=ON` ausente: integridad referencial NO forzada
**Dónde:** `lib/core/database/database.dart:351-354` (`_openConnection`, solo fija WAL + `busy_timeout`).
**Qué:** SQLite trae las foreign keys **apagadas por defecto por conexión**, y drift no las activa. Todas las relaciones (`payments→orders`, `order_items→orders`, `refunds→orders/order_items/employees`, `orders→shifts`, etc.) dependen 100 % de la lógica de la app. Un bug o un dato mal formado puede dejar **filas huérfanas en silencio** — grave en un sistema de dinero.
**Impacto:** integridad de datos a largo plazo; un `employeeId` inexistente (ver A3) o un `orderItemId` colgado no se detecta.
**Fix:** agregar `db.execute('PRAGMA foreign_keys=ON;')` en el `setup`. **Cuidado:** activarlo sobre una BD con huérfanos preexistentes puede hacer fallar operaciones; acompañar de un chequeo único (`PRAGMA foreign_key_check`) al migrar y limpiar/loggear lo que aparezca. Recomendado hacerlo dentro de una migración v6.

### A2 — Reembolso sin tope: se puede devolver más de lo pagado
**Dónde:** `lib/core/services/refund_service.dart:37` (solo valida `amount <= 0`).
**Qué:** `RefundService.refund` no valida que `amount ≤ total pagado − reembolsos previos`. La UI ([orders_screen.dart](lib/features/admin/screens/orders_screen.dart)) pre-llena el total pero el campo es libre; un cajero/gerente puede teclear más.
**Impacto:** pérdida monetaria real y descuadre del corte Z (el `refundsTotal` resta del efectivo esperado).
**Fix:** en el servicio, cargar `getRefundsForOrder`, calcular `yaReembolsado`, y rechazar si `amount > order.total − yaReembolsado` (con tolerancia de centavos). Validar en el servicio (no solo UI) por ser dinero.

### A3 — Reembolso con `employeeId: actor?.id ?? 0` (empleado inexistente)
**Dónde:** `lib/features/admin/screens/orders_screen.dart:407`.
**Qué:** si no hay sesión activa, se registra un `refund` con `employeeId = 0`, que no existe en `employees`. Con A1 arreglado, esto **lanzaría**; hoy crea un dato huérfano.
**Impacto:** reembolso no atribuible + dato inválido.
**Fix:** abortar con aviso si `actor == null` antes de reembolsar (nunca usar `?? 0` para una FK). Mismo patrón revisar en cualquier `?? 0` sobre FKs.

---

## Hallazgos MEDIOS

### M1 — Cobro no valida que los pagos cubran el total (defensa en profundidad)
**Dónde:** `lib/core/services/checkout_service.dart` (`checkout` / `chargeExistingOrder`) — insertan los `PaymentDraft` y marcan `'pagado'` sin verificar la suma.
**Qué:** el servicio confía en que el `PaymentModal` ya validó la cobertura. Si un caller (o un futuro bug de UI) manda tramos que suman menos que el total, la orden queda **pagada con faltante**.
**Fix:** validar en el servicio que `Σ(amountTendered − changeGiven) ≥ total` (tolerancia de centavos) antes de marcar pagado; lanzar si no. Barato y blinda el punto más crítico.

### M2 — Fuga menor de listener: `ref.listenManual` sin cerrar
**Dónde:** `lib/app.dart:96` (`_startKdsServer`).
**Qué:** la suscripción de `ref.listenManual(ordersProvider, …)` no se guarda ni se cierra en `dispose`. `_Root` vive toda la sesión, así que es benigno, pero si se re-monta (hot reload, reset de sesión) queda un listener colgado referenciando el server.
**Fix:** guardar el `ProviderSubscription` y cerrarlo en `dispose`, o mover a `ref.listen` dentro de `build`.

### M3 — Broadcast WS en cada tick de 2 s aunque nada cambie
**Dónde:** `lib/app.dart` (listen a `ordersProvider`) + `orders_provider.dart` (`loadActiveOrders` crea lista nueva cada poll → siempre notifica).
**Qué:** el POS retransmite el snapshot cada 2 s aun sin cambios. Funciona y es barato en local, pero es tráfico innecesario.
**Fix (opcional):** difear por contenido (hash/igualdad del snapshot) antes de `broadcast`, o emitir solo en cambios reales.

### M4 — Cobertura de tests de **widgets** casi nula
**Dónde:** `test/widget_test.dart` (8 líneas, solo smoke). Los 104 tests son casi todos de servicio/unidad.
**Qué:** nada de la UI nueva tiene test de widget: `PaymentModal` (pagos mixtos, propina, cambio), anular línea en `OrderQueuePanel`, diálogo de reembolso, KDS all-day/paginado. La lógica de dinero del modal (saldo pendiente, cambio solo en efectivo) solo se validó a mano.
**Fix:** agregar `testWidgets` para al menos el flujo de pagos mixtos del modal y el cálculo de cambio; es la zona de mayor riesgo de regresión.

### M5 — Anulación de línea reescala montos proporcionalmente (aprox. con descuento fijo)
**Dónde:** `lib/core/providers/orders_provider.dart` (`voidOrderItem`) — ya documentado en el código.
**Qué:** reescalar `discount/tax/total` por la razón de subtotales es **exacto** para descuentos porcentuales e IVA, pero **aproximado** si la orden llevaba un descuento fijo (poco común en cafetería). Aceptable; se anota para trazabilidad.
**Fix (si se quiere exactitud):** recomputar con el motor de impuestos desde las líneas activas + el descuento original (requiere persistir el descuento aplicado, hoy solo se guarda el monto).

---

## Hallazgos BAJOS / notas

- **B1 — Token WS en texto plano.** `kds_endpoint.json` (`<appDir>/latercia/`) guarda `{port, token}` legible por cualquier proceso local. Aceptable para un kiosko en `127.0.0.1`; **anotar para el endurecimiento de la Fase 6** (permisos de archivo, o token efímero en memoria compartida).
- **B2 — Sin límite de tamaño/rate en el WS.** Local y con token, riesgo bajo; un `maxMessageSize` no estorbaría.
- **B3 — Propina en pago mixto** se adjunta al primer tramo (etiqueta para el reporte). Las sumas (`tipsTotal`) son correctas, pero no refleja "en qué método se dejó la propina". Menor.
- **B4 — Recall es un slot único global** en el `OrdersNotifier` del POS: si el KDS embebido y el separado marcan listo casi a la vez, el recall solo deshace el más reciente. Comportamiento heredado, ahora compartido por WS. Anotar.

---

## Lo que está BIEN (no re-tocar)

Cobro atómico (`CheckoutService` en una transacción, incl. pagos mixtos), auditoría append-only con gate de supervisor, WAL + `busy_timeout`, migraciones una-por-fase (v5), motor de IVA por línea con 16 tests, WS **con fallback a BD** (robusto ante caída), backups con checkpoint + retención + inyección de dir para test, KDS all-day/paginado sin encoger, salud del sistema, atribución de turno al cobrar (fix de la 5.5). 104 tests, `analyze` limpio, build Windows OK.

---

## Estado de corrección (2026-07-15)

**Resueltos** (108 tests verdes, analyze limpio, build Windows OK):
- ✅ **A3** — guard de sesión en reembolso (`orders_screen.dart`): sin actor no se reembolsa; `employeeId` siempre real.
- ✅ **A2** — tope de reembolso en `RefundService` (`amount ≤ total − reembolsos previos`), validado en el servicio. +1 test.
- ✅ **M1** — `CheckoutService._assertCovers`: rechaza pagos que no cubren el total (dentro de la transacción → rollback). +1 test.
- ✅ **A1** — `PRAGMA foreign_keys=ON` en `beforeOpen` (todas las conexiones, incl. tests) + migración v6 con `foreign_key_check` que loggea huérfanos preexistentes sin bloquear. Suite completa verde con FKs activas.
- ✅ **M2** — suscripción de `ref.listenManual` guardada y cerrada en `dispose` (`app.dart`).
- ✅ **M3** — dedup de broadcast en `KdsServer` (no reenvía snapshots idénticos del tick de 2 s).
- ✅ **M4** — tests de widget del `PaymentModal` (`payment_modal_test.dart`): cambio en efectivo y pago mixto (cambio solo en efectivo).

**Cerrados en la tanda de Fase 6 (2026-07-15):**
- ✅ **B1** — token WS con `chmod 600` en POSIX (`writeKdsEndpoint`).
- ✅ **B2** — `KdsServer`: tope de clientes (8) y de tamaño de mensaje (4 KB), ignora payloads no-string.
- ✅ **B3** — la propina de un pago mixto se adjunta al **tramo que cierra** el cobro (no al primero).

**Resueltos como "por diseño" / decisión del usuario:**
- 🔵 **M5** — el usuario eligió **aceptar la aproximación**: la reescala al anular línea ya es exacta para descuento porcentual e IVA (los casos reales); solo aproxima con descuento de monto fijo (combo raro), documentado en `voidOrderItem`. Sin migración v7.
- 🔵 **B4** — recall de slot único **es intencional**: un solo "deshacer" global del último "listo", ahora compartido por WS. Comportamiento aceptado, sin cambio.

**Todo lo listado en la auditoría queda resuelto o decidido.** (M3 se había cerrado ya en la tanda anterior.)

---

## Orden de corrección recomendado

```
1. A3  (trivial: guard actor null en reembolso)           — S
2. A2  (tope de reembolso en el servicio + test)          — S
3. M1  (validar cobertura de pagos en checkout + test)    — S
4. A1  (foreign_keys=ON en migración v6 + foreign_key_check) — M  (hacer al final del bloque de integridad, con backup)
5. M2  (cerrar listenManual)                              — S
6. M4  (tests de widget del PaymentModal)                 — M
7. M3/M5/B1–B4  (mejoras/notas, oportunistas)             — S c/u
```

**A1 al final del bloque** porque cambia el comportamiento de la BD y conviene hacerlo tras cerrar A2/A3/M1 (que eliminan las fuentes de datos huérfanos), con un backup previo y el `foreign_key_check` de red de seguridad.

**Nota:** A1 es la única que implica migración de esquema (v6). El resto son cambios de lógica/tests sin tocar esquema.
