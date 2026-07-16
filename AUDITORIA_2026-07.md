# Auditoría Técnica — La Tercia POS + KDS
**Fecha:** 2026-07-15 · **Alcance:** arquitectura, brechas funcionales, KDS, hardware ESP32, procedimientos
**Base:** código actual (post-rediseño visual) + auditoría 2026-06-30 (C1–C6 resueltos, 31 tests verdes)

---

## 1. Arquitectura y Gestión de Estado (Flutter)

### 1.1 Estado actual (verificado en código)

| Componente | Implementación actual |
|---|---|
| UI multi-pantalla | Un ejecutable, dos modos: POS (proceso principal) y KDS (segundo proceso vía `Process.start(exe, ['kds', --x/--y/--w/--h])`), o KDS embebido como tab en la misma ventana |
| Estado | Riverpod: `StateNotifierProvider` (órdenes), `StreamProvider` (catálogos), `AsyncNotifier` (settings) |
| Persistencia | Drift/SQLite, archivo único compartido entre ambos procesos |
| Sincronización POS↔KDS | Polling cada 2 s en `OrdersNotifier` (`orders_provider.dart`) |
| Transaccionalidad | `sendToKitchen` transaccional (fix C2). **Cobro NO:** `insertPayment` y `markPaid` son escrituras separadas |

### 1.2 Diagnóstico

1. **Dos escritores sobre un mismo archivo SQLite** funciona, pero es el punto más frágil del sistema. Los streams de Drift no cruzan procesos; de ahí el polling. Riesgos: latencia fija de 2 s, `database is locked` bajo escrituras concurrentes si no hay WAL + `busy_timeout` explícitos, y N+1 en `loadActiveOrders` (una query de items por orden, cada 2 s, ×2 procesos — I6 pendiente).
2. **Lógica de negocio en widgets.** `payment_modal.dart` escribe directamente en 3 DAOs. Para un sistema transaccional crítico, el cobro debe ser una unidad atómica en una capa de servicio, no una secuencia de awaits en un `StatefulWidget`.
3. **Riverpod es la elección correcta** para este tamaño de equipo/proyecto; migrar a BLoC no aporta nada aquí. Lo que falta no es otro gestor de estado sino **una capa de servicios**.

### 1.3 Recomendaciones (en orden de impacto/costo)

1. **Un solo dueño de la base de datos.** El proceso POS es el único que abre SQLite; la ventana KDS separada pasa a ser un *viewer* que recibe estado por WebSocket local (`ws://127.0.0.1:PUERTO`). Beneficios: elimina el locking multi-proceso, latencia <50 ms en lugar de 2 s, y **el mismo servidor WS sirve después para el ESP32** (pilar 4). El KDS embebido (misma ventana) ya evita el problema y debe seguir siendo el modo recomendado con una sola pantalla.
2. Mientras se mantenga el esquema actual: fijar `PRAGMA journal_mode=WAL` y `PRAGMA busy_timeout=5000` explícitos al abrir la conexión, y reemplazar el N+1 por un `JOIN` (una query para órdenes+items).
3. **`CheckoutService`** (capa `lib/core/services/`): `crearOrden + insertarPago + marcarPagado + incrementarVisitas` dentro de **una sola transacción Drift** (cierra también el I9 de inventario). UI → Notifier → Service → DAO; los widgets no tocan DAOs.
4. **Offline-first:** ya lo es al 100 %. Si algún día se requiere nube: patrón *outbox* (tabla de eventos append-only + worker de sincronización), nunca sync directo de tablas.

---

## 2. Funcionalidades Core de un POS Comercial (Análisis de Brechas)

### 2.1 Lo que YA está (y en buen estado)

Catálogo con categorías/modificadores con alcance por categoría (I3), mesas con estado, empleados con PIN **hasheado** + migración v2 (C5), clientes con visitas, descuentos con vigencia y monto mínimo aplicados en checkout (I1/I2), órdenes con ciclo de vida correcto pagado≠entregado (C1), devolución de inventario al cancelar (C4), numeración sin carreras (C3), backup/restore con staging y validación de cabecera SQLite (C6), reportes básicos, 31 tests unitarios.

### 2.2 Brechas para grado comercial

| # | Módulo | Estado | Detalle |
|---|---|---|---|
| G1 | **Control de caja / turnos** | ⚠️ Esquema muerto | Tabla `Shifts` + DAO existen, **cero UI**. Falta: apertura con fondo inicial, arqueo, corte **X** (parcial informativo) y **Z** (cierre con contador consecutivo e inmutable), diferencias de caja, retiros/depósitos de efectivo (paid-in/paid-out) |
| G2 | **Impresión térmica + gaveta** | ❌ No existe | ESC/POS (USB/red) para ticket de venta y **comanda en cocina** (respaldo del KDS: la industria no opera KDS sin impresora de contingencia). Gaveta por pulso RJ11 de la impresora. Paquete: `esc_pos_utils` + socket/USB raw. Registrar cada apertura de gaveta (ver pilar 5) |
| G3 | **Propinas** | ❌ | Captura en cobro (%, monto, en tarjeta), reparte por turno, columna en corte Z |
| G4 | **Pagos mixtos / split** | ❌ | Un solo método por orden hoy. Falta pago dividido (efectivo+tarjeta) y separar cuenta por comensal |
| G5 | **Devoluciones / anulación parcial** | ❌ | Hoy solo cancelación total desde admin. Falta: void de línea antes de cocina, reembolso parcial post-pago con motivo y autorización de supervisor |
| G6 | **Impuestos** | ⚠️ Parcial | Un `tax_rate` global. Falta: tasa por producto, impuestos compuestos, precio con impuesto incluido vs añadido, desglose en ticket. (Facturación CFDI queda explícitamente fuera de alcance local; prever exportación CSV/JSON contable) |
| G7 | **Roles granulares** | ⚠️ Parcial | Hoy binario admin/cajero. Falta matriz de permisos: anular, descuento manual, abrir gaveta sin venta, corte Z, reimprimir |
| G8 | **Auto-lock de sesión** | ❌ (I4) | PIN re-solicitado tras N min de inactividad o tras cada venta (configurable) |
| G9 | **Reimpresión / historial de ticket** | ⚠️ | El recibo es un diálogo efímero; debe poder reimprimirse desde Órdenes con marca "REIMPRESIÓN" |
| G10 | **Backup automático** | ⚠️ | Manual hoy; falta programado (diario) + checkpoint WAL antes de copiar (bug conocido: `downloadBackup` puede perder escrituras recientes) |

### 2.3 Checklist de validación del flujo de venta/cancelación (estándar industria)

- [x] Toda venta genera orden numerada única e inmutable
- [x] Cobro y estado de preparación independientes (pagar no oculta la comanda)
- [x] Envío a cocina atómico (orden+items+inventario o nada)
- [x] Cancelación devuelve stock y exige motivo
- [ ] Cancelación post-pago genera **contra-movimiento** (reembolso auditado), no borra
- [ ] Anulación de línea individual con motivo
- [ ] Toda operación sensible queda en audit trail con empleado y timestamp (pilar 5)
- [ ] Corte Z inmutable con consecutivo; las ventas quedan selladas a un turno
- [ ] Ticket físico entregable y reimprimible

---

## 3. Funciones y Flujos del KDS

### 3.1 Estados

Máquina actual: `pendiente → en_preparacion → listo → entregado` (+`cancelado`). Es correcta. **"Retrasada" debe seguir siendo un estado *derivado* del timer, no persistido** — así está hoy (umbrales ámbar/rojo configurables en Settings) y es lo recomendado: evita escrituras periódicas y estados zombis.

### 3.2 Recomendaciones

1. **Sonido por diff de IDs, no por conteo** (I8, pendiente): el `length compare` actual no suena si entra una orden y sale otra en el mismo tick de polling. Mantener `Set<int>` de IDs vistos.
2. **Recall:** botón "última orden marcada lista" (deshacer, ventana de ~60 s). **Crítico al introducir la botonera física** — el error de dedo es la falla #1 de un bump bar.
3. **Alto tráfico:** vista consolidada *all-day* (suma de items pendientes: "7× Frappé de Café") junto al grid de tarjetas; paginación si hay >12 tarjetas en vez de encoger tarjetas (legibilidad a 2 m de distancia es requisito de cocina).
4. **Orden de despacho:** FIFO por `createdAt` (ya implementado) con excepción visual para tipo *delivery* si se define SLA distinto.
5. El timer ya cuenta desde `createdAt` con refresh de 1 s y cambia verde→ámbar→rojo con parpadeo en rojo — correcto; solo falta que el umbral se lea una vez por build (ya) y documentar que el reloj del equipo es la única fuente de tiempo.

---

## 4. Integración de Hardware (ESP32 — botonera KDS)

### 4.1 Decisión de transporte

| Criterio | **USB Serial (CDC)** ⭐ | WebSocket Wi-Fi | BLE |
|---|---|---|---|
| Latencia | <1 ms | 5–30 ms | 30–100 ms+ |
| Estabilidad Windows | Alta (COM port) | Alta | **Baja** (stack BLE de escritorio problemático) |
| Alimentación | Por el mismo USB | Fuente aparte | Fuente/batería |
| Reconexión | Re-open de puerto, trivial | Re-connect WS, trivial | Pairing frágil |
| Dependencias | Ninguna | Red local estable | — |

**Recomendación: USB Serial como transporte primario.** La botonera vive junto a la segunda pantalla del mismo equipo; el cable USB la alimenta y elimina red y pairing. Paquete Flutter: `flutter_libserialport`. **WebSocket como variante opcional** si la botonera debe montarse lejos del equipo — y encaja con la arquitectura del pilar 1.3 (el servidor WS local ya existiría). **BLE: descartado** para escritorio Windows.

### 4.2 Protocolo (aplica a Serial y WS)

```
ESP32 → Host:  {"seq":123,"btn":3,"ev":"press","ts":456789}
Host  → ESP32: {"ack":123}
Ambos: heartbeat cada 2 s  {"hb":1}
```

- **`seq` monotónico + ACK:** el ESP32 guarda eventos no confirmados en un ring buffer (~32) y los reenvía; el host deduplica por `seq`. Una pulsación jamás se pierde ni se duplica aunque el host esté ocupado.
- **Debounce en firmware** (~30 ms hardware/software), no en Flutter.
- **Heartbeat bidireccional:** 3 heartbeats perdidos → el host marca la botonera "desconectada" (indicador en el header del KDS) y reintenta abrir el puerto con backoff exponencial (1 s→2 s→4 s, techo 10 s). Al reconectar, el ESP32 reenvía su buffer pendiente.
- **Pérdida de energía del ESP32:** sin estado persistente en el micro — todo el estado vive en el POS; al reiniciar solo se re-registra (`{"hello":"kds-pad-v1"}`). El firmware debe habilitar el watchdog (WDT) para auto-reset ante cuelgues.
- **Si WS:** servidor bind solo a `127.0.0.1`/interfaz LAN definida + token estático en el handshake.

### 4.3 Mapeo de botones (semántica bump bar)

Botones 1–N = posición de tarjeta en pantalla (1 = más antigua) para **marcar lista**; + botón dedicado **Recall** (3.2.2) y botón **En prep** modal opcional. Evitar cualquier esquema que requiera "seleccionar" primero con otro botón: dos pulsaciones por comanda es el doble de latencia operativa.

---

## 5. Procedimientos y Utilidades

### 5.1 Excepciones y logging

Hoy: try/catch ad-hoc con SnackBars; sin logging persistente. Implementar:

1. `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError` como triple red global.
2. Logger a archivo rotativo (`%APPDATA%/latercia/logs/latercia-YYYY-MM-DD.log`, retención 30 días, paquete `logger` + sink propio). Niveles: `INFO` operaciones, `WARN` reintentos/reconexiones, `ERROR` excepciones con stack. **Nunca** registrar PINs ni datos de tarjeta.
3. Los `catch (_) {}` silenciosos existentes (audio, backup) deben al menos loggear en `WARN`.

### 5.2 Audit trail (antifraude)

Tabla nueva **append-only** (sin UPDATE/DELETE desde la app):

```sql
audit_log(id, ts, employee_id, action, entity, entity_id, detail_json)
```

Eventos mínimos a registrar: login/logout (y PIN fallido ×3), venta cobrada, cancelación con motivo, descuento aplicado manualmente, ajuste de inventario, apertura de gaveta (con o sin venta), cambio de configuración, apertura/cierre de turno, reimpresión de ticket. Con esto se habilitan los dos reportes antifraude estándar: **anulaciones por empleado** y **aperturas de gaveta sin venta** — los dos vectores de merma más comunes en mostrador.

**Gap concreto detectado:** `inventory_movements` no guarda `order_id`; un movimiento "venta" no es rastreable a su ticket. Añadir la columna (migración v3) cierra la trazabilidad inventario↔venta.

### 5.3 Pendientes heredados de la auditoría 2026-06 (siguen abiertos)

I4 (auto-lock), I5 (pago por id), I6/I7 (N+1 en reportes y polling), I8 (sonido KDS por IDs), I9 (transacción de inventario — queda absorbido por el `CheckoutService` del pilar 1), checkpoint WAL en `downloadBackup`.

---

## Plan de ataque sugerido (prioridad × riesgo)

| Fase | Contenido | Justificación |
|---|---|---|
| **F1 — Integridad** | `CheckoutService` transaccional (I9), WAL+busy_timeout, JOIN anti-N+1 (I6), checkpoint WAL en backup | Riesgo de corrupción/inconsistencia monetaria; es la base de todo lo demás |
| **F2 — Caja** | UI de turnos sobre la tabla `Shifts` existente, cortes X/Z, audit_log + auto-lock (I4) | Sin control de caja no hay producto comercial; el esquema ya existe |
| **F3 — Hardware** | Impresora ESC/POS + gaveta (G2), botonera ESP32 por Serial + recall en KDS | La impresora es prerequisito operativo; la botonera reutiliza el canal de eventos |
| **F4 — Ventas avanzadas** | Propinas, pagos mixtos, anulación de línea, reimpresión | Completa el estándar de industria |
| **F5 — Escala** | KDS viewer por WS local (un solo dueño de BD), backups programados, impuestos por producto | Preparación para múltiples estaciones/sucursal |
