# Auditoría de Production-Readiness — La Tercia POS + KDS
**Fecha:** 2026-07-17 · **Alcance:** integridad transaccional, kiosko Linux, hardware ESP32, backups/logs, insumos/recetas, envío por zona
**Base:** código actual tras Fases 1–8 (insumos/recetas, modificador "incluido", envío por zona, catálogo real cargado) — reemplaza a `AUDITORIA_2026-06-30.md` y `AUDITORIA_2026-07_post_F5.md`, ya resueltas e incorporadas.
**Metodología:** hallazgos verificados directamente contra el código (archivo:línea citado en cada punto), no genéricos. Severidad: 🔴 Alto/Crítico · 🟡 Medio · 🟢 Bajo/informativo · ✅ Ya correcto (verificado, sin acción).

---

## Pilar 1 — Integridad transaccional y lógica de insumos

**🔴 `decrementForSale` puede alargar la transacción de cobro sin límite**
`CheckoutService.checkout()` (`lib/core/services/checkout_service.dart`) envuelve orden+items+inventario+pago en un solo `_db.transaction()`. Para productos con receta, `InventoryDao._adjustRecipeStock` (`lib/core/database/daos/inventory_dao.dart`) recorre cada línea de receta con select+update+insert secuenciales. Con un carrito grande de productos con receta, la transacción mantiene el lock de escritura de SQLite todo ese tiempo. Como POS y KDS son procesos separados compartiendo el mismo archivo, el KDS puede recibir "database is locked" si su escritura (`markReady`, etc.) cae en esa ventana y excede `busy_timeout=5000ms`.
→ Fix: acotar/medir el caso de carritos grandes con receta antes de confiar en que no pasará en la práctica.

**🟡 Hard-delete de Categoría/Producto sin manejo de FK**
`categories_dao.dart`/`products_dao.dart`: `deleteCategory`/`deleteProduct` son `DELETE` directos sin try/catch. Con `foreign_keys=ON` (desde v6), borrar una categoría con productos, o un producto con `order_items`/`recipe_items`, lanza `SqliteException` que se propaga sin capturar desde `categories_screen.dart:_delete` y `products_screen.dart:_confirmDelete`. Cualquier intento de borrar un producto que ya apareció en una venta (la mayoría) truena sin mensaje explicativo.
→ Fix: try/catch en ambos call sites + mensaje "no se puede eliminar: tiene productos/ventas asociadas".

**✅ Ya correcto:** Insumos/Proveedores/Zonas de envío usan soft-delete (`setActive`) exclusivamente — no exponen ningún método de hard-delete.

---

## Pilar 2 — Kiosko Linux (`cage` + `sddm`)

**🔴 Sin fallback de software rendering para pantalla negra**
Ningún archivo en `linux_kiosk/` menciona `LIBGL_ALWAYS_SOFTWARE`/`GALLIUM_DRIVER=llvmpipe`/`cage -s`. La única defensa contra pantalla negra es humana (probar `cage` manualmente antes de activar autologin), no automática ni en runtime.
→ Fix: variante del `.desktop`/servicio con `LIBGL_ALWAYS_SOFTWARE=1` documentada como Plan C.

**🟡 `StartLimitIntervalSec=0` desactiva el rate-limit de crash-loop a propósito**
`latercia-kiosk.service`: `Restart=always` + `RestartSec=2` + `StartLimitIntervalSec=0` — decisión consciente ("nunca dejar de intentar"), pero un crash inmediato genera loop de reinicio cada 2s para siempre, sin techo ni alerta visible desde afuera.
→ Mantener la política (es correcta para un kiosko desatendido); considerar loguear el contador de reinicios para que el health-check del Dashboard lo lea.

**🟢 Confirmado:** modo `cage` puro (vía SDDM) no tiene `Restart=always` — si la app truena ahí, la sesión termina y queda en negro hasta reinicio manual. El servicio systemd es alternativo, no complementario.

**🟡 `LinuxPrinterTransport` sin timeout**
A diferencia de `NetworkPrinterTransport` (timeout de 5s explícito), la ruta USB/CUPS no tiene `Duration timeout`. Además, la ruta CUPS (`lp -d ... -o raw`) casi siempre devuelve código 0 aunque la impresora esté físicamente desconectada — CUPS encola el trabajo sin esperar impresión real.
→ Fix: agregar `.timeout(Duration(seconds: 8))` a ambas ramas; documentar que la ruta CUPS no garantiza impresión física.

**🔴 No existe impresión física del corte Z**
Rastreado el flujo completo de cierre de turno: `close_shift_dialog.dart` → `ShiftService.closeShift` solo renderiza `CutTicket` en pantalla y permite exportar CSV. Ningún código llama a `printService` en ese flujo. Si se espera un tickét físico del corte Z, hoy no existe.
→ Decisión pendiente: ¿se necesita impresión física del corte Z, o pantalla+CSV es suficiente?

---

## Pilar 3 — ESP32 / WebSocket (botonera)

**🟡 Sin debounce en el servidor de la botonera**
`KdsButtonService._handleRequest` (`lib/core/services/kds_button_service.dart`) emite un evento por cada mensaje crudo recibido, sin ventana de debounce. Rebote mecánico de un botón físico generaría múltiples eventos idénticos seguidos → sonido repetido, toasts repetidos, escrituras duplicadas a BD, y — desde el reenvío cross-proceso agregado esta sesión — reenvío duplicado a la ventana KDS separada.
→ Fix: debounce (~150-200ms) en `KdsButtonService` antes de emitir al stream — arregla el problema en un solo lugar para ambos consumidores.

**✅ Ya correcto:** `KdsClient` (WS de sincronización POS↔KDS) reconecta con backoff 1→2→4→10s.

---

## Pilar 4 — Backups y logs

**🔴 La copia del backup no es atómica; puede quedar truncada ante un apagón**
`BackupService.backupNow`: `PRAGMA wal_checkpoint(TRUNCATE)` + `src.copy(dest)` directo. El checkpoint en sí es seguro (SQLite garantiza el .db principal consistente aunque se corte la luz a medio checkpoint). El problema es la copia del archivo, que no es atómica: cortar la luz a medio `copy()` deja el respaldo truncado/corrupto.
→ Fix: copiar a `.tmp` y hacer `rename()` al nombre final — atómico en el mismo volumen, así un backup nunca queda a medias.

**🟡 El checkpoint no verifica si fue completo**
`PRAGMA wal_checkpoint(TRUNCATE)` devuelve `(busy, log, checkpointed)`, ignorado por el código actual. Con un lector concurrente (KDS a media consulta del poll) el checkpoint puede quedar parcial sin fallar, y el backup copiaría el `.db` sin las transacciones más recientes, sin aviso.
→ Fix: leer el resultado del PRAGMA y reintentar/loguear si `checkpointed < log`.

**🟢 Logs — retención correcta pero sin tope de tamaño**
`app_logger.dart`: purga por antigüedad (30 días) corre solo una vez, al arrancar la app. En un kiosko que corre semanas sin reiniciar, los logs viejos se acumulan hasta el próximo arranque. Sin tope de tamaño total.
→ Fix: purga periódica (`Timer.periodic` cada 24h, no solo en `init()`) + tope duro de tamaño total como red de seguridad.

---

## Pilar 5 — Insumos y recetas

- Migración v7 (6 tablas nuevas + `usesRecipe`): orden de `DELETE` en la herramienta de reset respeta las FK (insumos/recetas/movimientos antes que productos/categorías) — correcto.
- `decrementForSale`/`incrementForSale` gateados por `insumos_activo` Y `product.usesRecipe`, cubierto por tests (`checkout_service_test.dart`, `ingredients_dao_test.dart`).
- Insumos/Proveedores/Zonas usan soft-delete — sin riesgo de FK huérfano.
- Gap real ya cubierto en Pilar 1: el bucle secuencial de `_adjustRecipeStock` dentro de la transacción de cobro.

## Pilar 6 — Modificador "incluido" + Envío por zona

- El flag `included` vive solo en el JSON de `modifiersJson`, nunca en la tabla `Modifiers` — correcto, es estado por línea de carrito, no del catálogo.
- 🟢 `_deliveryFee`/`_deliveryZoneName` en `pos_screen.dart` usan `ref.read()` dentro de getters llamados durante `build()` — funciona hoy porque `_buildOrderTypeRow` sí hace `watch()` en el mismo ciclo y fuerza la re-evaluación, pero es un acoplamiento implícito frágil (si se quita ese `watch()`, el total de envío dejaría de actualizarse sin error visible).
- Nada más grave — es lógica de UI/cálculo, no toca integridad de datos.

---

## Orden de trabajo acordado (2026-07-17) — TODOS RESUELTOS

1. ✅ **Backup no atómico** → `BackupService.backupNow` copia a `.tmp` + `rename()` atómico; también limpia `.tmp` huérfanos de intentos interrumpidos y verifica si el checkpoint del WAL quedó parcial (`busy`/`checkpointed < log`). 6 tests nuevos/actualizados en `backup_service_test.dart`.
2. ✅ **Delete de Categoría/Producto sin manejo de FK** → try/catch en `categories_screen.dart:_delete` y `products_screen.dart:_confirmDelete`, captura `SqliteException` y muestra el motivo al usuario. 5 tests nuevos en `fk_delete_test.dart` confirman que la FK realmente dispara esa excepción.
3. ✅ **Corte Z sin impresión física** → nuevos `PrintService.buildCutTicket`/`buildCutTicketPdf`/`printCutTicket` (ESC/POS + PDF, mismo patrón que venta/comanda), botón "Imprimir" en `CutTicket` (disponible tanto al cerrar turno como en el historial de Turnos). 5 tests nuevos en `print_service_test.dart`.
4. ✅ **Debounce de botonera** → `KdsButtonService` ignora repeticiones del mismo botón dentro de 180ms (el stream crudo de diagnóstico sigue viendo todo, sin filtrar). 3 tests nuevos en `kds_button_service_test.dart`.
5. ✅ **Timeout en `LinuxPrinterTransport`** → `Duration timeout` configurable (default 8s) en ambas ramas (escritura raw a `/dev/...` y cola CUPS `lp`), con `process.kill()` si `lp` se cuelga. Test de configuración en `print_service_test.dart`.
6. ✅ **Purga de logs periódica + tope de tamaño** → `AppLogger.init()` ahora también corre la purga cada 24h (no solo al arrancar), y `purgeOldLogs()` aplica un tope duro de 50MB borrando los archivos más antiguos si hace falta (nunca el de hoy). 5 tests nuevos en `app_logger_test.dart`.
7. ✅ **Software rendering fallback en kiosko** → documentado un "Plan B" en `setup.md` y `DESPLIEGUE_CLIENTE.md`: sesión Wayland alterna con `LIBGL_ALWAYS_SOFTWARE=1` para cuando `cage` falla por falta de GPU/driver (el caso real de la VM de pruebas), sin perder la sesión normal (se puede volver a la GPU real solo cambiando `Session=` en SDDM).

Verificación final: `flutter analyze` limpio, 173 tests verdes (+31 desde el inicio de esta auditoría), `flutter build windows --debug` exitoso.
