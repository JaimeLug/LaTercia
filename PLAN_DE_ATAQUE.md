# Plan de Ataque — La Tercia POS + KDS → producto comercial completo
**Fecha:** 2026-07-15 · **Fuente:** [AUDITORIA_2026-07.md](AUDITORIA_2026-07.md)
**Convención:** `[FLAG]` = funcionalidad opcional, activable en Configuración (default indicado). Tamaños: S (<½ sesión) · M (½–1 sesión) · L (1–2 sesiones).

**Regla general:** cada fase termina con `flutter analyze` limpio, suite de tests verde y verificación visual. Una migración de esquema por fase, no por tarea.

---

## FASE 1 — Integridad y base técnica
*Nada de lo demás es confiable sin esto. Sin migración de esquema.*

- [x] **1.1 (S)** WAL + `busy_timeout=5000` explícitos al abrir la BD (`database.dart`, `_openConnection`). Verificar con test de escrituras concurrentes.
- [x] **1.2 (M)** **Logging global**: `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError` → `lib/core/utils/app_logger.dart`, archivo rotativo `%APPDATA%/latercia/logs/latercia-YYYY-MM-DD.log`, retención 30 días. Reemplazar los `catch (_) {}` silenciosos por `WARN`. Nunca loggear PINs.
- [x] **1.3 (M)** **`CheckoutService`** (`lib/core/services/checkout_service.dart`): orden + items + inventario + pago + `markPaid` + visitas de cliente en **una transacción**. `payment_modal` y `pos_screen` dejan de tocar DAOs (cierra I9 e I5). Tests de atomicidad (fallo a mitad → rollback total).
- [x] **1.4 (M)** Anti-N+1: `getActiveOrdersWithItems()` con JOIN en `orders_dao`; `loadActiveOrders` pasa a 1 query. Igual en reportes (I6/I7).
- [x] **1.5 (S)** `downloadBackup`: `PRAGMA wal_checkpoint(TRUNCATE)` antes de copiar el `.db`.
- [x] **1.6 (S)** Sonido KDS por diff de `Set<int>` de IDs (I8).

**Criterio de salida:** cobro atómico demostrado por test; log file generándose; 0 N+1 en el polling.

---

## FASE 2 — Control de caja, seguridad y auditoría
*Migración de esquema → v3.*

**Migración v3:** tabla `audit_log(id, ts, employee_id, action, entity, entity_id, detail_json)` · columna `order_id` nullable en `inventory_movements` · columnas `shift_id` en `orders` y `payments` · tabla `cash_movements(id, shift_id, employee_id, type[deposito|retiro], amount, reason, ts)` · consecutivo Z en `shifts` (`z_number`).

- [x] **2.1 (M)** **`AuditService`** append-only + hooks en: login/PIN fallido×3, venta, cancelación, descuento manual, ajuste inventario, cambio de settings, apertura/cierre turno, reimpresión, apertura de gaveta.
- [x] **2.2 (L)** **UI de Turnos** sobre la tabla `Shifts` existente: abrir turno con fondo inicial (bloquea vender sin turno abierto `[FLAG: caja_requiere_turno, default ON]`), retiros/depósitos con motivo, cierre con arqueo (efectivo contado vs esperado → diferencia registrada).
- [x] **2.3 (M)** **Cortes X/Z**: X = informe parcial en cualquier momento; Z = cierre inmutable con consecutivo `z_number`, desglose por método de pago, propinas (F4), descuentos, cancelaciones. Vista imprimible/exportable.
- [x] **2.4 (S)** **Auto-lock** (I4): re-pedir PIN tras N min de inactividad `[FLAG: auto_lock_min, default 5, 0=off]` y opcionalmente tras cada venta `[FLAG: lock_tras_venta, default OFF]`.
- [x] **2.5 (M)** **Permisos granulares**: matriz por rol (anular, descuento manual, abrir gaveta sin venta, corte Z, reimprimir, editar catálogo). Roles: admin, gerente, cajero. Acción sin permiso → diálogo "PIN de supervisor" (queda en audit_log con ambos empleados).
- [x] **2.6 (S)** Reportes antifraude: anulaciones por empleado · aperturas de gaveta sin venta (pestaña en Reportes).

**Criterio de salida:** venta imposible sin turno (si flag ON); Z inmutable; toda operación sensible visible en audit_log.

---

## FASE 3 — Hardware e impresión
*El KDS necesita respaldo físico antes de la botonera.*

- [x] **3.1 (L)** **Impresión térmica ESC/POS** `[FLAG: impresion_activa, default OFF]`: `lib/core/services/print_service.dart` con `esc_pos_utils_plus`; transporte USB (raw) y red (socket 9100), configurable en Settings (tipo, dirección, ancho 58/80 mm). Plantillas: **ticket de venta** (logo, desglose, folio, empleado, leyenda) y **comanda de cocina** (grande, items+modificadores+nota). Cola de impresión con reintento y aviso si la impresora no responde.
- [x] **3.2 (S)** **Gaveta de dinero** `[FLAG: gaveta_activa, default OFF]`: pulso ESC/POS `DLE DC4`/`ESC p` vía la impresora. Botón "Abrir gaveta" (permiso 2.5) + apertura automática al cobrar en efectivo `[FLAG: gaveta_auto_efectivo, default ON si gaveta activa]`. Cada apertura → audit_log.
- [x] **3.3 (S)** **Reimpresión** (G9): botón en Órdenes (admin), marca "— REIMPRESIÓN —", registra en audit_log.
- [x] **3.4 (S)** **Recall en KDS**: deshacer la última orden marcada "listo" (ventana 60 s), botón en header. *Prerequisito de la botonera.*
- [ ] **3.5 (L)** **Botonera Arduino Uno** `[FLAG: botonera_activa, default OFF]`: *(POSPUESTA — requiere hardware para verificar. Microcontrolador: **Arduino Uno** en vez de ESP32 — el usuario ya tiene varios, costo ~0. Implica USB-serial cableado (CDC vía ATmega16U2), sin variante inalámbrica.)*
  - `lib/core/services/kds_pad_service.dart` con `flutter_libserialport`: autodetección de puerto (hello `kds-pad-v1`), frames JSON `{seq,btn,ev,ts}` + ACK, dedupe por `seq`, heartbeat 2 s, reconexión con backoff (1→2→4→10 s), indicador de estado en header del KDS.
  - Firmware Arduino Uno (sketch C++ en `firmware/kds_pad/`): baud 115200, debounce 30 ms, ring buffer 32 eventos (OJO 2 KB RAM), reenvío sin ACK, watchdog (`avr/wdt.h`).
  - Mapeo bump bar: botón N = tarjeta N (marcar listo), botón dedicado Recall. Configurable en Settings.

**Criterio de salida:** venta imprime ticket real; comanda impresa en cocina; botonera marca/recall órdenes con la app reiniciándose o el cable desconectándose sin perder pulsaciones.

---

## FASE 4 — Ventas avanzadas
*Migración de esquema → v4: `tips(payment_id, amount)` o columna `tip_amount` en payments · `payments` ya soporta N por orden (verificar UI) · columnas de impuesto por producto (`tax_rate`, `tax_included`) · `refunds(id, order_id, order_item_id?, amount, reason, employee_id, supervisor_id, ts)`.*

- [x] **4.1 (M)** **Propinas** `[FLAG: propinas_activas, default OFF]`: captura en modal de cobro (botones 10/15/20 % + monto libre), columna en corte Z y reporte por empleado/turno. No afecta el total de venta (línea separada). *(Hecho: columna `payments.tipAmount`; selector 10/15/20%+libre en `PaymentModal` tras flag; `_grandTotal`=venta+propina para cobro/cambio; `CheckoutService.checkout`+`chargeExistingOrder` guardan tip y auditan; `ShiftSummary.tipsTotal` en corte X/Z + CSV. Turno único ⇒ por-turno == por-cajero. 2 tests.)*
- [x] **4.2 (M)** **Pagos mixtos**: el modal de cobro permite N pagos parciales (efectivo+tarjeta+transferencia) hasta cubrir el total; cambio solo sobre el tramo en efectivo. *(Hecho: `PaymentDraft` + `CheckoutService.checkout`/`chargeExistingOrder` insertan N pagos en una transacción, auditan 'mixto'+methods; `PaymentModal` reescrito con lista de tramos parciales ("Agregar pago" / "Cobrar resto"), saldo pendiente en vivo, cambio solo en efectivo, campo de monto para tarjeta/transferencia; gaveta auto si algún tramo es efectivo. 1 test.)*
- [x] **4.3 (M)** **Anulación de línea**: antes de enviar (libre) · después de enviar (permiso + motivo + reimpresión de comanda "CANCELADO: item") · devolución de stock por línea. *(Hecho: antes de enviar = editar carrito ya existía; después de enviar = `OrdersNotifier.voidOrderItem` (transaccional: marca item 'cancelado', devuelve stock, reescala montos proporcional, audita 'anular_linea') solo en órdenes NO pagadas; botón por línea en detalle del `OrderQueuePanel` con motivo + gate `anular`; `PrintService.printItemCancellation` comanda "CANCELADO" best-effort. 1 test.)*
- [x] **4.4 (M)** **Reembolso parcial/total post-pago**: genera contra-movimiento en `refunds` (nunca edita la venta), exige supervisor, devuelve stock opcionalmente, refleja en Z y audit_log. *(Hecho: tabla `Refunds` + `RefundsDao`; `RefundService.refund` transaccional (valida orden pagada, restock opcional por línea/orden, liga al turno, audita 'reembolso'); `PermissionAction.reembolso` (gate supervisor para cajero); botón "Reembolsar" en Admin→Órdenes con monto/motivo/devolver-stock; `ShiftSummary.refundsTotal` resta del efectivo esperado + línea en corte X/Z + CSV. 2 tests.)*
- [x] **4.5 (M)** **Impuestos por producto** (G6): tasa por producto con default global, `tax_included` (precio con impuesto incluido vs añadido), desglose por tasa en ticket y reportes. `computeOrderTotals` en `pricing.dart` se extiende con tests. *(Hecho: motor `computeTaxedTotals` por línea + `effectiveTaxRate/Included` + `taxIsIncludedInTotal`, 16 tests; columnas `products.taxRate/taxIncluded` nullable=hereda global; flag global `tax_included` (default IVA incluido); UI en catálogo; etiqueta "IVA incluido" en ticket/recibo/PDF.)*
- [ ] **4.6 (S)** **Split de cuenta** `[FLAG: split_activo, default OFF]`: dividir la orden en N sub-cuentas por item para cobrar por separado (cafetería: baja prioridad, flag OFF). *(POSPUESTO por decisión del usuario 2026-07-15: baja prioridad para cafetería; flag `split_activo` ya sembrado en OFF. Retomar si se necesita.)*

**Criterio de salida:** los flujos de `pricing_test.dart` extendidos y verdes; cobro mixto y reembolso auditados de punta a punta. *(Cumplido: 93 tests verdes, `flutter analyze` limpio. 4.1–4.5 hechas; 4.6 split pospuesto.)*

---

## FASE 5 — Escalabilidad y pulido
- [x] **5.1 (L)** **Un solo dueño de BD**: servidor WebSocket local en el proceso POS (`dart:io HttpServer`, bind 127.0.0.1, token); la ventana KDS separada pasa a viewer WS (latencia <50 ms, sin polling ni locking multi-proceso). El KDS embebido queda igual. *(La botonera es Arduino Uno cableado por USB-serial, no inalámbrica, así que este WS es independiente de ella.)* *(Hecho con **WS + fallback a BD** (decisión del usuario): `KdsServer` (puerto efímero 127.0.0.1 + token por sesión, publica endpoint en `kds_endpoint.json`, broadcast de snapshots, ejecuta comandos vía callbacks al OrdersNotifier del POS); `KdsClient` (lee endpoint, reconecta con backoff 1→2→4→10s); `kds_link.dart` (serialización con `toJson`/`fromJson` de drift + comandos). `OrdersNotifier` gana modo cliente: conectado ⇒ estado por push WS y comandos (listo/estado/recall) por WS (sin tocar BD); desconectado ⇒ vuelve al polling de BD. POS arranca el server en `_Root.initState` y retransmite en cada cambio; el proceso KDS override `ordersProvider` con `KdsClient`. 5 tests (round-trip, token, broadcast, comando). **Falta verificación runtime con las 2 ventanas** (no testeable desde aquí, como la botonera).)*
- [x] **5.2 (M)** **Backups automáticos** `[FLAG: backup_auto, default ON, diario]`: copia con checkpoint a `%APPDATA%/latercia/backups/` con retención N días + al cerrar turno. *(Hecho: `BackupService` (checkpoint+copy timestamped, poda por retención, `last_backup_at`, `baseDir` inyectable para test); auto diario al entrar al POS + al cerrar turno; UI en Configuración→Respaldo (toggle + retención); flags `backup_auto`/`backup_retention_days`. 4 tests.)*
- [x] **5.3 (M)** **KDS alto tráfico**: vista all-day consolidada ("7× Frappé de Café") + paginación de tarjetas (nunca encoger, legibilidad a 2 m). *(Hecho: `_buildAllDay` (consolida cantidades pendientes por producto, texto grande) + toggle en header; `_buildPaginatedGrid` con `LayoutBuilder` (tarjetas de tamaño fijo, lo que no cabe pasa de página) + barra Página X/Y + auto-rotación cada 12s.)*
- [x] **5.4 (S)** Indicadores de salud en Admin: estado impresora/botonera/último backup/tamaño de log. *(Hecho: `SystemHealthCard` + `systemHealthProvider` en el Dashboard: impresora (de settings), botonera (no configurada), último backup (fecha+tamaño, warn si >2 días), tamaño de logs (`AppLogger.logsSizeBytes`).)*
- [x] **5.5 (M)** Suite de integración: flujo completo venta→cocina→cobro→corte Z sobre BD en memoria. *(Hecho: `integration_flow_test.dart` (2 tests) ejercita abrir turno→cocina→listo→cobro con propina→corte Z y un ciclo con reembolso. **Destapó y arregló un bug**: las órdenes diferidas ("Enviar a Cocina") no se atribuían al turno → `chargeExistingOrder` ahora estampa `order.shiftId` al cobrar (`OrdersDao.updateOrderShift`).)*

---

## FASE 6 — Linux + kiosko *(LO ÚLTIMO de todo)*
*Meta: PC estilo kiosko que al encender arranque directo en la app con TODAS las funcionalidades. Desarrollo/pruebas en **máquina virtual Linux** mientras se prepara la estación física del cliente. Va al final porque necesita la máquina real (y comparte etapa física con la botonera 3.5).*

**Estado de compatibilidad hoy (revisado 2026-07-15):** la app ya corre en Linux casi sin cambios — rutas vía `path_provider`/`driftDatabase(name:)` (caen en `~/.local/share/latercia/`), SQLite+WAL multiproceso igual que en Windows, impresora de **red** (socket 9100) ya cross-platform. Único hueco: impresión **USB** (spooler win32).

- [x] **6.1 (S)** **Transporte de impresión USB para Linux**: agregar `LinuxPrinterTransport` (CUPS/`lp` o escritura raw a `/dev/usb/lp0`) junto al `WindowsRawPrinterTransport` existente en `print_service.dart`; seleccionar por `Platform`. Si la impresora del kiosko es de red, esto no bloquea nada. *(Hecho: `LinuxPrinterTransport` (`/dev/...` → RAW directo; si no → cola CUPS `lp -o raw`); `printerTransportFromSettings` ramifica USB por `Platform`. 4 tests. Runtime real = VM del usuario.)*
- [x] **6.2 (M)** **Empaquetado kiosko**: `flutter build linux`; autoarranque del binario al iniciar sesión (systemd `--user` service o autostart del entorno gráfico), pantalla completa/sin barra de ventanas, y arranque coordinado de los dos procesos (POS + ventana KDS) — o consumir ya el KDS-viewer-por-WS de 5.1 para no depender de dos procesos sobre el mismo archivo. *(Hecho a nivel de código/config: carpeta `linux_kiosk/` (unit systemd `Restart=always`, autostart `.desktop`, `setup.md` con build/instalación/impresora/autologin/`cage`); pantalla completa vía `KioskController`. El `flutter build linux` real lo corre el usuario en la VM.)*
- [ ] **6.3 (S)** **Pruebas en VM**: validar en máquina virtual Linux el flujo completo (login→venta→cocina→cobro→corte Z), rutas de datos/backups, y el arranque kiosko, antes de pasar a la estación física del cliente. *(PENDIENTE — lo hace el usuario en su VM Linux; checklist en `linux_kiosk/setup.md` §6.)*
- [x] **6.4 (S)** **Endurecimiento de kiosko**: deshabilitar atajos de salida/consola, ocultar escritorio, arranque tolerante a fallos (si la app crashea, reiniciarla), y respaldo de la BD sobreviviendo reinicios. *(Hecho: `KioskController` (flag `modo_kiosko`) pone pantalla completa + `setPreventClose` (bloquea cierre; escape = apagar el flag en Configuración, reactivo); tolerancia a fallos vía systemd `Restart=always`; los backups viven en `~/.local/share/latercia/` fuera del bundle → sobreviven reinicios; token WS con `chmod 600` (B1). `cage` documentado para kiosko duro.)*

**Criterio de salida:** VM Linux enciende → app en pantalla completa con todas las funciones (incluida impresión y, si ya hay hardware, botonera), sin escritorio visible ni forma trivial de salir. *(Código/config 6.1/6.2/6.4 listos y verdes; falta la validación runtime 6.3 en la VM del usuario. Flags nuevos: `modo_kiosko` (OFF).)*

---

## Resumen de flags nuevos en Configuración
`caja_requiere_turno` (ON) · `auto_lock_min` (5) · `lock_tras_venta` (OFF) · `impresion_activa` (OFF) · `gaveta_activa` (OFF) · `gaveta_auto_efectivo` (ON) · `botonera_activa` (OFF) · `tax_included` (ON=IVA incluido) · `propinas_activas` (OFF) · `split_activo` (OFF) · `backup_auto` (ON)

## Orden y dependencias
```
F1 (base) → F2 (caja+auditoría) → F3 (hardware) → F4 (ventas) → F5 (escala) → F6 (Linux/kiosko, lo último)
              └─ 2.1 audit_log es prerequisito de 3.2 gaveta y 4.4 reembolsos
              └─ 3.4 recall es prerequisito de 3.5 botonera (Arduino Uno)
              └─ 3.1 impresora es prerequisito de 3.2 gaveta y 3.3 reimpresión
              └─ 3.5 botonera y toda la F6 comparten la etapa de hardware físico + VM
              └─ 5.1 KDS-por-WS simplifica el arranque kiosko de 6.2
```
F4.5 (impuestos) y F5.2 (backups) pueden adelantarse en paralelo si se necesita.
