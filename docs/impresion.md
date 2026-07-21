# Impresión (ESC/POS térmica y PDF) y gaveta

Código en `lib/core/services/print_service.dart`. Todo el hardware vive detrás
de flags (`impresion_activa`, `gaveta_activa`) y es genérico/multimarca (ESC/POS
estándar, sin nada atado a un modelo). La generación de documentos se prueba a
**nivel de bytes**; el envío real por socket/spooler no se puede verificar sin
hardware.

## Dos modos de impresión

- **Térmica** (`printer_mode = 'termica'`): bytes ESC/POS crudos a una impresora
  térmica. Es el modo normal de tickets.
- **Gráfica** (`printer_mode = 'grafica'`): renderiza el ticket a **PDF** y lo
  manda a cualquier impresora de Windows (inyección, láser, o térmica con
  driver). Para locales sin impresora térmica dedicada.

## Gaveta de dinero

El pulso estándar de apertura es `ESC p 0 25 250` (`0x1B 0x70 0x00 0x19 0xFA`) →
pin 0, on-time 25, off-time 250. Son los bytes exactos que casi todas las
gavetas conectadas a la impresora esperan.

> **No** se usa `Generator.drawer()` de esc_pos_utils_plus: ese emite
> `ESC p '0' '3' '0'` (dígitos ASCII), que no es el pulso canónico.

Hay un comando alterno `DLE DC4 0 1 0` (`0x10 0x14 0x00 0x01 0x00`) que algunas
gavetas usan en su lugar.

## Transportes (cómo salen los bytes)

Un `PrinterTransport` es el canal que envía los bytes crudos. Lanza si falla; la
`PrintQueue` captura, reintenta, y tras agotar los reintentos reporta sin romper
la venta. `printerTransportFromSettings` elige cuál según `printer_transport` y
`printer_address` (null si no hay dirección → la cola avisa "no configurada").

### Red (`NetworkPrinterTransport`, socket RAW 9100)

Abre el socket, escribe, hace flush y **cierra grácilmente** (`close()` con
timeout), con `destroy()` solo como red de seguridad en `finally`.

> **Bug del cierre abrupto (instalación 18-jul):** el ticket de venta —el más
> grande, y el primero de la pareja venta+comanda— no salía, mientras la comanda
> sí. Causa: `socket.destroy()` es un cierre **abrupto** que puede descartar
> bytes todavía en vuelo antes de que el otro extremo (impresora lenta, o el
> puente `socat`→`/dev/usb/lp0`) los drene. El documento grande enviado primero
> es la víctima; los chicos alcanzan a salir. Fix: `close()` grácil espera a que
> todos los bytes en buffer se envíen antes de soltar el socket.

### Windows (`WindowsRawPrinterTransport`, spooler)

Envía bytes **RAW** por el API de Windows: `OpenPrinter` → `StartDocPrinter`
(DOC_INFO_1 con `pDatatype = 'RAW'`, para que el spooler no procese los bytes) →
`StartPagePrinter` → `WritePrinter` → `EndPagePrinter` → `EndDocPrinter` →
`ClosePrinter`. Todos los handles y la memoria nativa se liberan en `finally`.

### Linux (`LinuxPrinterTransport`, CUPS o `/dev/usb/lp0`)

- Si el destino empieza con `/dev/`: escritura **RAW directa** al dispositivo,
  con timeout (por si el USB se desconecta a media escritura).
- Si no: cola **CUPS** vía `lp -d <cola> -o raw`, alimentando los bytes por
  stdin. `lp` devuelve 0 en cuanto **encola** (no espera a que se imprima
  físicamente); un 0 no garantiza impresión real, solo que CUPS aceptó el
  trabajo.

## Utilidades de impresión

- **`listWindowsPrinters`**: enumera las impresoras de Windows (`EnumPrinters`
  nivel 4, patrón de dos llamadas) para el desplegable de Configuración. Lista
  vacía fuera de Windows o si falla.
- **`isVirtualPrinter`**: detecta impresoras virtuales que **no** son térmicas
  (PDF, XPS, OneNote, Fax, "Microsoft Print to…") — no entienden ESC/POS crudo,
  así que enviarles un ticket produce basura. Se usa para avisar en la UI.
- **`paperColumns`**: ancho real de línea del papel — 32 columnas a 58 mm,
  48 a 80 mm.
- **`sanitizeTicketText`**: las fuentes de impresión (latin1 en ESC/POS,
  Helvetica en PDF) no soportan toda la puntuación Unicode. Sustituye raya larga,
  comillas tipográficas, "…", etc. por equivalentes ASCII y descarta cualquier
  code unit fuera de 0..255, para no romper nunca los bytes ni el layout del PDF.
- **`testTicketPreviewLines`**: texto plano del ticket de prueba al ancho real,
  para una **vista previa en pantalla** sin impresora (y sin caer en la trampa de
  "imprimir" a un PDF que no entiende ESC/POS).

## Logo del ticket térmico

`_resolveThermalLogo` carga el logo configurado (o el default `assets/images/8.png`),
lo decodifica y lo reescala a ~300 px de ancho para el comando de imagen ESC/POS.
En modo gráfico, `_resolveLogo` da el `ImageProvider` para el PDF.

## Cola de impresión con reintento (`PrintQueue`)

Serializa los envíos (una cola FIFO) y reintenta N veces ante un fallo de
transporte; tras agotar los intentos, reporta el fallo **sin lanzar** hacia la
venta (best-effort: cobrar nunca debe fallar porque la impresora esté offline).

## Documentos que se generan

Cada documento tiene su builder de **bytes ESC/POS** (`buildSalesTicket`,
`buildKitchenTicket`, `buildDeliveryTicket`, `buildCutTicket`, `buildTestTicket`)
y su equivalente **PDF** (`build*Pdf`) para el modo gráfico. El TOTAL se resalta
en video inverso (ESC/POS) o caja negra (PDF). Los cortes X/Z incluyen folio.
