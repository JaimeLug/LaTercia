# Respaldos y restauración

Código en `lib/core/services/backup_service.dart` (respaldo automático,
exportación, restauración parcial) y `lib/core/utils/backup_helper.dart`
(descargar/restaurar el `.db` completo). La pantalla es Admin → Backups.

## Rutas (importante)

- La **base de datos real** vive en `getApplicationSupportDirectory()/latercia.sqlite`
  (en Linux, `~/.local/share/mx.latercia.pos/`). Ver `database.dart`.
- Los **backups y logs** van a **Documentos** (`Documentos/latercia/backups`,
  `.../logs`), a propósito, para que un técnico los encuentre y copie a mano.

> Son carpetas **distintas** a propósito. `BackupService` toma dos
> resolvedores separados (`baseDir` para backups/logs, `dbDir` para el archivo
> real). Antes ambos asumían la misma carpeta y los backups automáticos fallaban
> en silencio (best-effort) sin respaldar nada. `backup_helper.dart` tuvo el bug
> inverso (apuntaba a Documentos en vez de a la carpeta de soporte); ver el
> commit del fix.

## Respaldo automático (`.db` completo)

- Corre **una vez por día** calendario y **al cerrar turno** (si `backup_auto`
  está ON). Todo best-effort: nunca lanza ni bloquea la venta.
- Antes de copiar hace `PRAGMA wal_checkpoint(TRUNCATE)` para volcar el WAL al
  `.db` e incluir lo recién escrito. Si un lector concurrente (el KDS a media
  consulta) deja el checkpoint parcial, se loguea (no bloquea).
- **Copia atómica:** copia a un `.tmp` y luego renombra (rename atómico en el
  mismo volumen), así un corte de luz nunca deja un backup truncado con el
  nombre final. Los `.tmp` huérfanos de un intento interrumpido se limpian en el
  siguiente backup.
- **Retención:** borra los backups más viejos que N días (`backup_retention_days`,
  default 14; `0` = no borrar).

## Exportación selectiva (`.sql` / `.xlsx`)

Solo de **exportación** (reportes / revisar datos) — **nunca** se reimportan.
El usuario elige qué tablas incluir (agrupadas: Catálogo, Personas, Operación,
Inventario, Envío, Sistema).

- **`.sql`**: el `CREATE TABLE` real de cada tabla (tal cual en `sqlite_master`)
  + un `INSERT` por fila. Escapa comillas y serializa blobs como `x'...'`.
- **`.xlsx`**: una hoja por tabla, encabezados = nombres de columna.

> **Por qué no se reimportan:** reconstruir una BD relacional (con sus llaves
> foráneas) desde un `.sql`/Excel editado a mano es donde se corrompen los datos.
> El único formato de **restauración** real es el `.db` completo.

## Restauración parcial por grupo (asistente de fusión)

Ver `docs/restauracion-parcial.md`.
