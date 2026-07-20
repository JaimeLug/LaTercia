# Plan de actualización grande — La Tercia POS
**Fecha de la sesión:** 2026-07-18 (noche) · **Próxima visita al sitio:** semana del 2026-07-19
**Origen:** sesión de trabajo tras la instalación en sitio del 18-jul. Bitácora completa de la instalación: `C:\Users\jaime\Downloads\BITACORA_INSTALACION_2026-07-18_1.md`.

> Documento de respaldo de TODO lo que se acordó y diagnosticó esta sesión, para no perder contexto. Nada de esto está programado todavía — se ejecuta a partir de la próxima sesión de trabajo. **No se tocó código esta noche (18-jul).**

---

## 0. Contexto del equipo instalado (referencia rápida)

- **Sitio:** La Tercia, Chicxulub Puerto. **PC:** HP EliteDesk 705 G1 SFF · Lubuntu 24.04 · usuario Linux **`latercia`** (NO `pos`).
- **Impresora:** Qian Anjet 80 Ultra térmica 80 mm, **USB** (`lsusb`: `0456:0808`), dispositivo `/dev/usb/lp0`, cola CUPS `termica` (raw). Hoy la app imprime vía **puente socat** (TCP 9100 → `/dev/usb/lp0`, servicio `printer-bridge.service`) porque la UI no dejaba configurar USB en Linux (ver A1).
- **Kiosko:** NO se usó `cage` (junta los 2 monitores en un lienzo). Se usó escritorio normal + autologin SDDM + script `kiosk-launch.sh` con `wmctrl` que ancla cada ventana a su monitor (POS en `VGA-0`, KDS en `DisplayPort-1`).
- **Red:** IP fija en la PC `192.168.0.162/24` vía `nmcli` (el router Tenda no expone reserva DHCP). ESP32 botonera reconfigurado a esa IP, puerto 8080. Funciona.
- **Rutas de datos REALES hoy:** base viva en `~/Documentos/latercia.sqlite` (+ `-wal`/`-shm`); backups y logs en `~/.local/share/com.example.latercia/latercia/`.

---

## 1. Bugs de código a arreglar (la actualización grande)

### A1 — 🔴 Impresión USB en Linux (sí o sí)
- **Causa raíz:** el transporte `LinuxPrinterTransport` YA existe y funciona (`lib/core/services/print_service.dart:353`: cola CUPS `lp -o raw` o `/dev/usb/lp0` directo). El problema es la **UI de Configuración**: en modo "usb" muestra `_buildUsbPrinterPicker` → `listWindowsPrinters()` (solo Windows) y NO ofrece campo de texto en Linux → "No se detectaron impresoras instaladas en Windows", sin forma de teclear la cola CUPS ni la ruta del dispositivo (`lib/features/admin/screens/settings_screen.dart:596`).
- **Fix:** si `Platform.isLinux` y transporte "usb", mostrar un **campo de texto libre** (hint: `Nombre de cola CUPS (ej. termica) o /dev/usb/lp0`) en vez del picker de Windows. Renombrar la opción del desplegable de "USB / impresora de Windows" a "USB / impresora local".
- **Impacto:** elimina la necesidad del puente socat en futuras instalaciones.

### Fix de impresión — 🔴 el ticket de venta no imprime (bytes perdidos)
- **Síntoma (corregido por el usuario):** al cobrar —incluso ANTES de enviar a cocina— solo sale **un** ticket, la **comanda**; el **ticket de venta/cliente NO sale**. Los tickets de PRUEBA sí salen. Esto descarta la hipótesis previa del flujo delivery.
- **Análisis de código (a fondo):** el flujo es correcto. Cobro directo → `pos_screen._openPayment` → `PaymentModal(printKitchenComanda=true)` → `payment_modal.dart:239` `printSaleAndKitchen`, que **encola el ticket de venta PRIMERO y la comanda DESPUÉS**, en serie por el mismo transporte (`PrintQueue._tail`, `print_service.dart:471`). Si la comanda (2ª, más chica) sale y el ticket de venta (1º, más grande) no → el fallo está en el **transporte**, no en la lógica.
- **Sospechoso concreto:** `NetworkPrinterTransport.send` (`print_service.dart:67-75`) hace `socket.add(bytes)` → `await socket.flush()` → y en `finally` un **`socket.destroy()`**. `destroy()` es cierre abrupto: puede descartar bytes en vuelo antes de que socat los drene a `/dev/usb/lp0`. El ticket de venta (más grande, enviado primero) es la víctima probable; comanda y ticket de prueba (chicos) sobreviven.
- **Fix:** cambiar `socket.destroy()` por cierre grácil **`await socket.close()`** (garantiza entrega de todos los bytes). Ayuda también con impresoras de red reales.
- **Confirmación con el log del sitio** (`~/.local/share/com.example.latercia/latercia/logs/`): si NO aparece el warning "La impresora no responde (Ticket …)", la app creyó que envió OK → confirma que fue el `destroy()`/puente, no un error de construcción del ticket. **No es bloqueante:** el fix ya está claro sin el log.

### A2 — 🟡 PINs duplicados entre empleados (sí o sí)
- **Hueco:** la identificación de cajero es solo por PIN. Dos empleados con el mismo PIN = auditoría por empleado ambigua. (Nota: `Employees.pin` ya es `unique()` en el esquema — verificar por qué no bloquea en la UI; puede faltar validación de mensaje amigable o el unique no cubre el caso de edición.)
- **Fix:** validación al crear/editar empleado que rechace un PIN si ya existe otro empleado **activo** con el mismo, con mensaje claro. Limpiar duplicados antes de migrar si los hubiera.

### A3 — 🟡 Rutas de datos (INVERTIR)
- **Acuerdo del usuario:** la **base debe vivir en `~/.local/share`** (getApplicationSupportDirectory) y los **backups deben ir a `~/Documentos`**. Hoy está al revés: base en `~/Documentos/latercia.sqlite` (default de `driftDatabase(name:)` = getApplicationDocumentsDirectory), backups+logs en `~/.local/share`.
- **Requiere:** cambiar la resolución de ruta de la base en `_openConnection()` (`database.dart:488`) y la de backups en `backup_service.dart`. Migración cubierta por el flujo reinstalar+restaurar.

### A4 — 🟢 Bundle ID sin personalizar
- Hoy es el placeholder `com.example.latercia` (se ve en la ruta de datos). Aprovechar la reinstalación limpia para cambiarlo a algo propio (ej. `mx.latercia.pos`). Cambia la carpeta de datos, por eso va junto con A3 en la reinstalación.

---

## 2. Tickets — mejoras pedidas por el dueño

### Ticket de venta/cliente
- Que imprima (lo resuelve el fix de bytes de arriba).

### Ticket de DELIVERY (feature nueva, NO solo plantilla)
- Se quiere un ticket de reparto con **nombre + teléfono + dirección** del cliente.
- **OJO scope — el modelo NO tiene dirección:** `Customers` (`database.dart:104`) = name/phone/email/notes, sin address. `Orders` (`database.dart:136`) = `customerName` nullable, sin address ni phone. La POS solo captura `_customerName` y `_orderNote`.
- **Requiere:** (1) migración drift (agregar dirección + teléfono, en `Orders` o vía `customerId`), (2) UI en la POS para capturarlos cuando el tipo es "delivery", (3) documento ESC/POS nuevo del ticket de reparto.

### Rediseño visual del ticket
✅ **HECHO (2026-07-20) — Logo en el ticket térmico.** El ticket PDF (modo "gráfica") YA tenía logo (`_resolveLogo`); el térmico ESC/POS —el que realmente se imprime en producción— no tenía nada. Se agregó `_resolveThermalLogo`: usa el logo personalizado de Configuración → Negocio (`logo_path`) si existe, si no cae a `assets/images/8.png` (el que el usuario señaló: negro puro sobre blanco, mejor contraste en 1-bit que el logo a color). Se reescala a 300px de ancho antes de mandarlo al generador (el archivo default viene a 3780×3780px — mandarlo tal cual sería lentísimo). Impreso arriba del nombre del negocio en `buildSalesTicket`. Paquete `image` (ya era dependencia transitiva) declarado directo en pubspec.yaml; `assets/images/8.png` agregado a los assets declarados (antes no estaba, así que `rootBundle` no lo encontraba). 2 tests nuevos (incluye uno que confirma que el comando ESC/POS de imagen realmente se emitió, no solo que "no truena"). Verificado con `flutter build windows --debug` exitoso además de analyze+tests.
**Pendiente:** ver cómo se ve físicamente impreso (solo confirmable en sitio/VM con impresora real).

**✅ HECHO (2026-07-20, más tarde la misma noche) — Segunda pasada de diseño**, a partir de una referencia visual (foto de un ticket con marco ornamentado/floral estilo IA) que el usuario compartió pidiendo "que se sepa que es de esa cafetería". Análisis honesto: ese diseño ornamentado NO es realista en térmica real (1 bit, 203dpi — el sombreado suave y las líneas finas de flores se ven manchadas; y un borde completo alrededor de todo el ticket sería lento de imprimir con fila de gente esperando). Se implementó la versión SÍ lograble:
- **Divisor de marca** (`_brandDivider`/`_brandDividerPdf`): patrón repetido `*  *  *  ...` en vez de línea plana, usado tras el encabezado y tras el TOTAL. A propósito solo ASCII (0-127) — las tablas de códigos de las térmicas varían por marca en el rango 128-255 (ahí van los acentos), pero el rango ASCII es idéntico en cualquier impresora; cero riesgo de que salga un símbolo distinto en una impresora que no se ha podido probar.
- **TOTAL en "caja"**: en térmica vía `reverse: true` (texto blanco sobre franja negra — capacidad NATIVA de la impresora, GS B 1/0, no imagen, sin costo extra de tiempo); en el PDF de vista previa vía un contenedor negro real (`_boxedTotalPdf`).
- 2 tests nuevos que fijan el comportamiento (confirman el comando `GS B 1`/`GS B 0` y el patrón del divisor en los bytes reales, no solo que "no truena").
- Verificado: `flutter analyze` limpio, **184 tests** verdes, `flutter build windows --debug` exitoso.
- **Explícitamente NO implementado** (bajo ROI o no realista en 1-bit): borde ornamentado completo, íconos por línea de producto, ilustración de fondo — quedan documentados como "no recomendado" salvo que el dueño consiga arte real diseñado para impresión térmica (no generado por IA con sombreados), en cuyo caso se conecta con el mismo mecanismo que ya usamos para el logo.

---

## 3. Cómo verificar TODO en la VM (sin la impresora física)

### Bug de bytes perdidos → prueba automática determinista
- Test de integración en Dart: levantar un `ServerSocket` local que **lea lento** (simula el USB lento), mandar el ticket grande, y assert de que llegan **todos** los bytes. Con `destroy()` falla (reproduce el bug), con `close()` pasa. **Corre hasta en Windows con `flutter test`**, sin VM.
- Nota: en `localhost` puro casi nunca se pierden bytes (muy rápido) → por eso el receptor debe leer lento para reproducir fielmente el caso del sitio.

### Verlo con los ojos en la VM → "impresora falsa" que captura a archivo
```bash
socat -u TCP-LISTEN:9100,fork,reuseaddr OPEN:/tmp/captura.bin,creat,append
```
App en "red" → `127.0.0.1`, hacer una venta, revisar `/tmp/captura.bin`: debe traer ticket de venta Y comanda completos (ambos terminando en el corte de papel).

### Contenido, layout y logo → vista previa en PDF (sin imprimir)
- La app ya genera el ticket como PDF (`buildSalesTicketPdf`) y Configuración → Impresión tiene "Vista previa". Ahí se itera el rediseño y el logo en pantalla.

### A1 (USB/CUPS Linux) → cola CUPS falsa en la VM
- Dar de alta una cola CUPS raw que escriba a un archivo (o `cups-pdf`); confirmar que `lp -o raw` recibe los bytes completos y que el nuevo campo de texto de Configuración apunta bien.

### Lo único que queda para el sitio
- Qué tan oscuro sale el logo y si el texto no se corta en papel de 80 mm → solo se confirma con la impresora real. Pero la **corrección** (nada truncado, contenido y layout correctos) queda 100% verificada en la VM antes de ir.

---

## 4. Proceso de actualización (deployment)

**Esta actualización es MAYOR** (cambia rutas de datos A3, bundle ID A4, y agrega columnas para delivery). Por eso el camino es reinstalación limpia + restaurar, como procedimiento escrito:

**Actualización grande (próxima visita), en orden:**
1. **Respaldo primero** (punto de no retorno): copiar la base viva `~/Documentos/latercia.sqlite` a USB.
2. **Reemplazar el bundle** en `/opt/latercia` con el compilado nuevo (rutas nuevas + bundle ID nuevo + migraciones).
3. **Restaurar datos:** colocar la base respaldada en la ruta nueva; al abrir, las migraciones drift corren solas y agregan columnas nuevas.
4. **Verificar:** catálogo, empleados, y prueba de fuego de impresión (venta + comanda + delivery + corte Z).

**Actualizaciones futuras (ya estabilizado):** reemplazar bundle + reiniciar. Datos se quedan quietos; migraciones drift manejan el esquema. Backup → cambiar bundle → reiniciar → verificar.

**Anti-corrupción de texto (lección de la bitácora §12):** llevar **un solo script de actualización probado** como `.sh`, correr `dos2unix` al llegar, teclado físico + `nano`, **nunca Okular**. Los "errores de Linux" del día de instalación fueron casi todos texto corrompido (separadores U+2029 de Okular, espacios comidos al copiar del celular).

**Higiene de versiones:** subir versión en `pubspec.yaml` en cada release + llevar un CHANGELOG de qué trae cada versión, para saber qué está instalado en el sitio.

---

## 5. Orden de trabajo acordado

1. ✅ **HECHO Y VERIFICADO (2026-07-20)** — **Fix del ticket** (`destroy()`→`close()`) + **A1** (impresión USB/CUPS Linux) + prueba automática. Mergeado a `main`. Verificado en la VM con una "impresora falsa lenta" (Python, lee de a 32 bytes con pausas de 30ms, emula el USB lento del sitio): una venta cobrada produjo **2 cortes de papel** (ticket de venta + comanda), ambos completos. Antes salía solo la comanda. *(Nota: la ruta directa CUPS de A1 —transporte "usb" apuntando a la cola `termica`— no se ejercitó aún; se probó vía "red" a 127.0.0.1, que es lo que usa el sitio por socat. La ruta CUPS se confirma en sitio o con una cola CUPS-a-archivo en la VM.)*
2. ✅ **HECHO Y MERGEADO A `main`** — **A2**, PINs únicos entre empleados activos (`EmployeesDao.pinInUseByActive` + validación en `employees_screen._save`). Confirmado en git: sus archivos ya no aparecen modificados en el working tree.
3. **A3 + A4** — rutas de datos invertidas + bundle ID nuevo (van con la reinstalación). ⏳ Pendiente.
4. ✅ **HECHO (2026-07-20)** — **Ticket de delivery**: migración v9 (`customerPhone`+`customerAddress` en `Orders`), UI en POS (campos teléfono/dirección visibles solo en delivery, validados como obligatorios junto con zona y nombre), `CheckoutService.checkout`/`OrdersNotifier.sendToKitchen` los propagan, y documento nuevo `buildDeliveryTicket`/`buildDeliveryTicketPdf` (nombre, teléfono, dirección, zona, lista de items sin precios, y "COBRAR AL ENTREGAR $total" si la orden no está pagada o "YA PAGADO" si sí) — se imprime junto a la comanda de cocina en ambos flujos (cobro directo y envío a cocina). 3 tests nuevos + verificado que `flutter analyze` del proyecto completo queda limpio. **Pendiente de verificar en la VM/sitio** (build real + impresión física).
5. ✅ **HECHO Y VERIFICADO (2026-07-20)** — **Bug de "Guardar" en Configuración**. Causa real, DOS bugs distintos en `settings_screen.dart`: (a) el `ColorPicker` ponía `_loaded = false` en cada cambio de color → `_loadFromSettings` repintaba desde la base ANTES de guardar nada, revirtiendo el color al instante; (b) `_save()` también ponía `_loaded = false`, y junto con el `AsyncLoading` que dispara `ref.invalidateSelf()`, la pantalla ENTERA se reemplazaba por un spinner un instante — se sentía como que Guardar borraba/revertía todo, aunque los datos sí quedaban persistidos. Fix: se quitó `_loaded = false` de los 2 `onColorChanged` y de `_save()`, y se agregó `skipLoadingOnReload: true` al `.when()` del provider. Prueba de widget nueva (`test/settings_screen_test.dart`, 2 tests) que reproduce el reporte exacto del usuario (switch se apaga tras Guardar) — **verificada con dientes**: revertido el fix a propósito, el test SÍ falla reproduciendo el bug; restaurado el fix, pasa.
6. 🟡 **PARCIAL (2026-07-20) — Módulo de actualizaciones, motor por USB.** Ver §7 para el diseño. Se construyó y probó a fondo el **backend** (sin UI todavía — eso queda para hacerlo despierto, viendo la pantalla real):
   - `lib/core/services/update_service.dart` — `UpdateService`: genera/lee manifiesto (sha256 por archivo + versión), verifica integridad de un paquete, compara versión contra la instalada (`compareVersions`, numérico por componente — no lexicográfico), y `applyUpdate`/`rollback` con **swap atómico** (copia a staging en el mismo volumen → verifica otra vez → `rename()` a respaldo → `rename()` del staging a la ruta activa) y **rollback automático** si el paso final falla — nunca deja la PC sin una app funcional. `rollback()` manual restaura el respaldo más reciente (por timestamp, con desempate si dos caen en el mismo milisegundo).
   - `lib/core/utils/app_version.dart` — `appVersion` (constante, hoy `1.0.0` — subir a mano junto con `pubspec.yaml` en cada release) + `compareVersions`.
   - `tool/generate_update_manifest.dart` — script que un técnico corre tras `flutter build linux --release` para producir `update_manifest.json` junto al bundle (antes de copiarlo al USB). **Corre como Dart puro** (`dart run`, sin Flutter) — probado de verdad contra un bundle de prueba, incluidos los casos de error (sin argumentos, directorio inexistente). Costó una vuelta: `update_service.dart` al inicio importaba `app_logger.dart` (→ `path_provider` → Flutter → `dart:ui`), lo cual rompía `dart run` fuera de la app; se quitó esa dependencia para que el servicio sea 100% Dart puro.
   - 16 tests nuevos en `test/update_service_test.dart` (con directorios temporales reales, no mocks): manifiesto íntegro/corrupto/incompleto, versión newer/same/older, caso feliz de `applyUpdate`, paquete corrupto NO toca la instalación, `installDir` inexistente, rollback sin respaldos, y rollback elige el respaldo MÁS RECIENTE (no el primero) tras dos actualizaciones seguidas.
   - Verificado: `flutter analyze` limpio, **200 tests** verdes (suite completa), `flutter build windows --debug` exitoso.
   - ✅ **HECHO (2026-07-20, mañana) — pantalla de Actualizaciones**, agregada dentro de `KioskScreen` (`lib/features/admin/screens/kiosk_screen.dart`, la pantalla "Quiosco" ya existente en el shell de admin, junto a Info del equipo/Acciones — se agregó ahí en vez de crear una pantalla nueva). Flujo: botón "Buscar paquete" → `FilePicker.platform.getDirectoryPath()` para elegir la carpeta del USB → lee el manifiesto (`UpdateService.readManifest`) → compara versión (`compareToInstalled`) → muestra versión instalada vs. candidata → botón "Aplicar actualización" (solo habilitado si es más nueva) con diálogo de confirmación → `UpdateService.applyUpdate(packageDir:, installDir: Directory(p.dirname(Platform.resolvedExecutable)))` → si tiene éxito, ofrece "Reiniciar ahora" (`PowerService.restartApp()`, confirmado que SÍ relanza el binario desde su ruta en disco, así que recoge la versión nueva). También se agregó "Versión instalada" al panel de info del equipo.
     - **Sin test automático para esta pantalla** — `KioskScreen._loadExtras()` ya llamaba (antes de esta sesión) a `backupServiceProvider` sin overrides, que golpea el canal de plataforma real de `path_provider`; mockearlo para una sola pantalla no se justificó por tiempo. Verificado solo con `flutter analyze` limpio + `flutter build windows --debug` exitoso — el flujo completo (elegir USB real, aplicar, reiniciar) queda pendiente de la prueba en VM.
   - Manual corregido (`linux_kiosk/MANUAL_ZERO_TO_PRODUCTION.md`: Fase 4 con wmctrl, ruta de BD, CUPS por CLI, usuario variable, IP fija nmcli, TTY regreso `Ctrl+Alt+F2`, aviso del filtro MAC "Lista negra" del Tenda) — **sigue pendiente**, no se tocó esta sesión.

---

### Pasada de calidad (2026-07-20, mañana) — antes de ir a la VM
`dart format --set-exit-if-changed` encontró 98 archivos con formato inconsistente (indentación/saltos de línea) — la mayoría código preexistente que nunca había pasado por `dart format` uniformemente, no solo lo tocado hoy. Se corrió `dart format` sobre todo `lib/`+`test/`+`tool/` (170 archivos): cambio puramente de estilo, dart_style nunca toca lógica/AST. Verificado que convergió a 0 cambios pendientes, y que analyze+**208 tests**+build siguen exactamente igual de verdes tras el formateo (no debía cambiar nada funcional, y no cambió).

## 6. Pendientes operativos del sitio (de la bitácora)
- Hoja de entrega: contraseña de `latercia`, IP `192.168.0.162`, cola CUPS `termica`.
- Confirmar que la contraseña del usuario `latercia` ya NO sea `1234`.
- Conseguir el log del sitio para confirmar el diagnóstico del ticket (no bloqueante).
- Revisar el turno/tickets con el dueño para anotar cualquier otro detalle de impresión.

---

## 6b. 🔴 URGENTE — Bug de navegación del KDS (reportado EN VIVO, café abierto, 2026-07-20)

**Síntoma reportado por el dueño en tiempo real:** con 6-7 pedidos activos en cocina, las primeras 4 tarjetas se ven bien, pero al presionar "Siguiente" la pantalla **salta de golpe a un lienzo completamente distinto** — las órdenes 5+ quedaban invisibles en "otra pantalla" hasta hacer clic. Pidió que fuera "más en vivo". También: tarjetas con muchos productos se cortaban (secundario, ya tenían scroll interno pero sin indicio visual de que existía); tarjetas un poco más grandes (menor).

**Causa raíz confirmada en código** (`lib/features/kds/kds_screen.dart`): `_buildPaginatedGrid` repartía las órdenes activas en **páginas fijas** (`active.sublist(start, end)`, `perPage = cols × rows` calculado del viewport) y el botón "Siguiente"/auto-rotate cada 12s hacían `setState(() => _page = ...)` — un swap instantáneo de TODO el contenido de la pantalla. Exactamente lo descrito.

**✅ HECHO Y VERIFICADO (misma noche):**
- Reemplazado por **scroll continuo**: nuevo widget público `KdsOrderGrid` (extraído para poder probarlo sin depender de audio/sockets de la botonera) — TODAS las órdenes activas viven en el mismo `SingleChildScrollView`+`Wrap` con `Scrollbar` visible, en vez de páginas separadas. Avanzar es desplazarse, no saltar.
- El auto-rotate (tablero de pared) ahora hace `animateTo` suave (600ms) en vez de un salto instantáneo de página.
- La selección de la botonera física (ANTERIOR/SIGUIENTE/PREP/LISTO) ahora **auto-desplaza la vista** (`_selectAndReveal` + `Scrollable.ensureVisible`) para traer la tarjeta seleccionada a pantalla — antes, con la paginación, la selección podía quedar en una "página" no visible.
- Tarjetas agrandadas (320×452 → 340×480) — pedido menor del dueño, de paso ayuda a que quepan más items sin scroll interno.
- `_SelectableCard` renombrado a público `SelectableOrderCard` (parte de la extracción de `KdsOrderGrid`).
- **3 tests nuevos** (`test/kds_order_grid_test.dart`): confirma que con 8 órdenes activas las 8 quedan en el árbol de widgets simultáneamente (antes solo las de la página actual), que no queda ningún indicador "Página X/Y", y que el resaltado de selección sigue funcionando.
- Nota técnica para el futuro: `ElapsedTimer` (el cronómetro de cada tarjeta) tiene una animación de parpadeo infinita para el aviso "atrasado" — por eso los tests de esta pantalla usan `pump()` en vez de `pumpAndSettle()` (que colgaría para siempre). Es la razón por la que no existían tests de esta pantalla antes.
- Verificado: `flutter analyze` limpio, **203 tests** verdes (suite completa), `flutter build windows --debug` exitoso.
- **Pendiente:** confirmar en la VM/sitio que el scroll se siente fluido en la pantalla real de cocina (touch o mouse, según cómo la operen) y que el auto-desplazamiento de la botonera se ve bien.

**✅ HECHO Y VERIFICADO (2026-07-20, mañana) — navegación vertical con los 6 botones físicos.** Pregunta clave del dueño: la cocina solo tiene 6 botones (dos flechas, recall, prep, listo, tiempo), sin mouse ni pantalla táctil. Anterior/Siguiente ya resolvían el movimiento horizontal (cambiar de orden), pero no había forma de bajar dentro de un pedido largo ni en la vista All-day (movimiento vertical) — la barra de scroll y el degradado con flecha son solo visuales, no interactivos sin mouse.
**Fix (diseño acordado con el dueño antes de tocar código):** Anterior/Siguiente ahora son contextuales:
- En vista **Tarjetas**, si la orden seleccionada tiene contenido oculto en esa dirección, el botón primero desplaza ESA tarjeta; solo al llegar al final (o si el pedido cabe completo, el caso común) pasa a seleccionar la orden siguiente/anterior — sin cambio de comportamiento para pedidos cortos.
- En vista **All-day**, Anterior/Siguiente desplazan la lista consolidada (ahí no hay "órdenes" entre las que cambiar).
- Deliberadamente NO se tocaron Recall/Prep/Listo para esto (son botones que confirman acciones; overloadearlos con "desplazar" sería peligroso).
Implementación: `KdsScreen` ahora posee un `ScrollController` por orden activa (antes cada `OrderCardKds` gestionaba el suyo aislado, invisible desde fuera) + uno para All-day, con poda/dispose junto a `_cardKeys`. `OrderCardKds.itemsScrollController` es un parámetro opcional (si no se pasa, sigue gestionando el suyo — no rompe el uso suelto en tests). 3 tests de integración nuevos (`test/kds_screen_botonera_scroll_test.dart`) que alimentan la botonera vía el provider (sin sockets reales, `kdsButtonStreamProvider.overrideWithValue`) y confirman con dientes reales: pedido largo → Siguiente desplaza antes de cambiar; pedidos cortos → cambia directo sin pausa; All-day → Siguiente sí mueve la lista. Nota de la sesión de pruebas: hubo que descubrir que el pump de 50ms entre presiones no dejaba completar la animación de 300ms (curva easeInOut, arranca lenta) — se subió a 350ms. Verificado: analyze limpio, **208 tests** verdes, build Windows exitoso.

**✅ HECHO Y VERIFICADO (2026-07-20, mañana) — la otra mitad del reporte: pedidos largos "cortados".** El usuario confirmó que no se había resuelto del todo: la tarjeta YA tenía scroll interno para los items (desde antes de anoche), pero sin ninguna señal visual de que hacía falta desplazar — se leía como "eso es todo el pedido" y se podía perder un producto. Fix en `lib/features/kds/widgets/order_card_kds.dart`: `Scrollbar` visible (mismo patrón que la cuadrícula) + degradado con flecha ↓ al pie de la lista de items, que aparece SOLO cuando de verdad hay contenido oculto por debajo (vía `NotificationListener<ScrollMetricsNotification>`, se recalcula en el layout inicial y en cualquier scroll). 2 tests nuevos (`test/order_card_kds_test.dart`): con 15 productos la flecha aparece, con 1 producto no aparece. Tuvo que ajustarse una prueba de `kds_order_grid_test.dart` que asumía "un solo Scrollbar en toda la pantalla" — ya no es cierto (cada tarjeta trae el suyo); se le dio Key propia (`kds-grid-scrollbar`) al de la cuadrícula para diferenciarlo. Verificado: analyze limpio, **205 tests** verdes, build Windows exitoso.

---

## 7. Módulo de actualizaciones (PLANEADO — producto multi-cafetería)

**Contexto:** el objetivo del producto es dejar de ser "solo La Tercia" y venderse a cafeterías. Instalar/actualizar a mano en cada sitio no escala → hace falta un **módulo de actualizaciones dentro de la app**.

**Aclaración técnica:** la app ya usa sockets, pero solo para comunicación LOCAL (KDS WS en 127.0.0.1, botonera ESP32 en :8080). Eso NO es un canal de actualización. Hay dos caminos, de menor a mayor complejidad:

- **A) Actualización por USB (empezar por aquí — simple y offline):** el técnico llega con una memoria que trae el bundle nuevo (o un paquete `.zip` versionado); dentro de la app, un flujo "Aplicar actualización" lo lee del USB, valida integridad (checksum), reemplaza `/opt/latercia` de forma **atómica** (copiar a un lado + swap, con respaldo del binario anterior para rollback), y reinicia. Las migraciones drift corren solas al abrir; los datos NO se tocan. Es básicamente automatizar el "reemplazar bundle + reiniciar" del §4, pero desde la UI, sin teclear comandos en Linux.
- **B) Actualización por red / OTA (después):** requiere un **servidor de actualizaciones** central alcanzable por internet. La app consulta "¿hay versión nueva?", descarga el bundle, verifica **firma** (no solo checksum — seguridad), aplica con swap atómico + rollback, y reinicia. Necesita: hosting del servidor, versionado, canal de firma, y manejo de fallos de red. Es lo ideal para escala (actualizas todas las sucursales sin ir), pero es un proyecto en sí.

**Requisitos comunes a ambos (diseñar desde ya):**
- **Versionado claro** (`pubspec.yaml` + CHANGELOG) para saber qué versión corre cada sitio.
- **Swap atómico + rollback:** si la versión nueva no arranca, volver sola a la anterior (crítico en un kiosko desatendido).
- **Integridad:** checksum (USB) / firma (red) antes de aplicar — nunca aplicar un paquete corrupto (recordar la corrupción de texto de la instalación en sitio).
- **Migraciones de datos** automáticas (drift ya lo hace) y datos intactos entre versiones.
- **Registro** de qué versión se aplicó y cuándo (para soporte).

**Orden sugerido:** primero USB (resuelve el dolor inmediato de actualizar en sitio rápido), luego OTA por red cuando haya varias sucursales.

---

*También guardado como memoria persistente: `latercia-actualizacion-grande-2026-07`.*
