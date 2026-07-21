# Documentación de La Tercia POS

Reglas de negocio y decisiones de diseño de la aplicación, rescatadas del
código durante la limpieza (2026-07). Cada archivo cubre un tema; el código
correspondiente enlaza aquí en un comentario corto en vez de repetir la
explicación larga.

## Índice

- [**Estándar de trabajo**](estandar-de-trabajo.md) — cómo ordenamos y
  documentamos: docs por dominio, comentarios cortos, puertas de calidad, git,
  checklist para un módulo nuevo. **Leer antes de empezar cualquier módulo.**
- [Base de datos (SQLite + Drift)](base-de-datos.md) — ubicación, acceso
  multiproceso (WAL), foreign_keys, migraciones.
- [Precios, descuentos e IVA](precios-e-iva.md) — cálculo de totales de una
  orden: descuentos, elegibilidad, IVA incluido vs. añadido, cálculo por línea.
- [Inventario e insumos](inventario.md) — stock simple vs. receta, punto único
  de descuento.
- [KDS (pantalla de cocina)](kds.md) — cursor de la botonera, encadenar "listo",
  parseo de modificadores.
- [KDS: comunicación y botonera](kds-conexion.md) — enlace POS↔KDS por
  WebSocket, botonera ESP32, el bug de RECALL.
- [Seguridad y PINs](seguridad.md) — hasheo de PINs, nunca loguear PINs.
- [Permisos y auditoría](permisos-y-auditoria.md) — acciones sensibles, PIN de
  supervisor, bitácora.
- [Ciclo de vida de las órdenes](ordenes-y-cocina.md) — enviar a cocina, listo,
  recall, cobrar, cancelar/anular, sync POS↔KDS.
- [Ventas, cobro, reembolsos y turnos](ventas-cobro-turnos.md) — cobro atómico,
  pagos mixtos, reembolsos, arqueo y cortes.
- [Impresión y gaveta](impresion.md) — ESC/POS térmica vs PDF, transportes,
  gaveta, logo, documentos.
- [Modo kiosko: energía y reinicio](kiosko.md) — apagar/reiniciar equipo o app.
- [Logs](logs.md) — bitácora a archivo, purga y tope de tamaño.
- [Versionado y actualizaciones](actualizaciones.md) — versión, comparación,
  motor de actualización por USB.
- [Respaldos y restauración](backups.md) — backup automático, exportación
  `.sql`/`.xlsx`, rutas.
- [Restauración parcial por grupo](restauracion-parcial.md) — asistente de
  fusión, grupos seguros, modos Agregar/Reemplazar.
- [Facturación (prellenado CFDI 4.0)](facturacion.md) — export de datos fiscales
  listos para timbrar (no timbra); flujos individual y global, catálogos SAT.

> Este índice crece conforme se van limpiando más archivos.
