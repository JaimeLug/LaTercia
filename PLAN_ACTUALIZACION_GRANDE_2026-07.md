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
- El dueño dijo que "se ve muy mal". Poner el **logo arriba** y mejorar el layout de `buildSalesTicket`.
- **Logo:** ya existe en el repo → `assets/images/logo-color.png` y `assets/images/logo-white.png` (+ PNGs 5–9). Para térmica hay que generar un **bitmap monocromo de alto contraste** (~576 px de ancho para 80 mm) e imprimirlo como raster ESC/POS.

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
2. **A2** — PINs únicos. ⏳ Pendiente.
3. **A3 + A4** — rutas de datos invertidas + bundle ID nuevo (van con la reinstalación). ⏳ Pendiente.
4. **Ticket de delivery** (migración + captura + documento) y **rediseño con logo**. ⏳ Pendiente.
5. **Bug de "Guardar" en Configuración** ⏳ Pendiente — al presionar **Guardar** en cualquier sección de Configuración, la UI regresa a un **estado anterior** y NO persiste los cambios: los switches ("puntos corredizos") que se habían activado se **apagan** y se **pierden datos** capturados. Hay que **mantener** el botón Guardar pero corregir que revierta/pierda lo configurado. (Detalle técnico por investigar en `settings_screen.dart` — sospecha inicial: interacción entre `_loadFromSettings` con su guard `_loaded`, el refresh del `settingsProvider` tras guardar, y/o el manejo de estado por categoría al volver a la vista de tarjetas.)
6. **Script de actualización + módulo de actualizaciones** ⏳ Pendiente (ver §7, empezar por USB) + **manual corregido** (`linux_kiosk/MANUAL_ZERO_TO_PRODUCTION.md`: Fase 4 con wmctrl, ruta de BD, CUPS por CLI, usuario variable, IP fija nmcli, TTY regreso `Ctrl+Alt+F2`, aviso del filtro MAC "Lista negra" del Tenda).

---

## 6. Pendientes operativos del sitio (de la bitácora)
- Hoja de entrega: contraseña de `latercia`, IP `192.168.0.162`, cola CUPS `termica`.
- Confirmar que la contraseña del usuario `latercia` ya NO sea `1234`.
- Conseguir el log del sitio para confirmar el diagnóstico del ticket (no bloqueante).
- Revisar el turno/tickets con el dueño para anotar cualquier otro detalle de impresión.

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
