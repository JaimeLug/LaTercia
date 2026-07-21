# Base de datos (SQLite + Drift)

Código en `lib/core/database/database.dart` (esquema, conexión, migraciones) y
los DAOs en `lib/core/database/daos/`. La base es SQLite vía Drift.

## Ubicación y acceso multiproceso

- El archivo vive en `getApplicationSupportDirectory()/latercia.sqlite` (en
  Linux, `~/.local/share/mx.latercia.pos/`). Ver `docs/backups.md` §Rutas.
- **POS y KDS son dos procesos** que comparten el mismo archivo. Se usa
  **WAL** (`journal_mode=WAL`) para que lectores y escritores avancen en
  paralelo en vez de bloquearse en un único lock de escritura, y `busy_timeout`
  para que SQLite reintente hasta 5 s en vez de lanzar "database is locked" de
  inmediato cuando los dos procesos chocan en una escritura.

## Integridad referencial (foreign_keys)

Desde A1, las llaves foráneas se **fuerzan** (`PRAGMA foreign_keys = ON`), por
conexión, fuera de transacción, en cada apertura (requisito de SQLite) —
incluidos los tests. Esto es lo que hace que, por ejemplo, borrar un producto con
ventas falle en vez de dejar datos huérfanos (base de la red de seguridad de la
restauración parcial, ver `docs/restauracion-parcial.md`).

## Migraciones

El esquema tiene versión; `onUpgrade` aplica los cambios incrementales de una
versión a otra. Cada bloque `if (from < N)` documenta su propio paso en el
código (es el mejor lugar para esa nota). Puntos notables:

- **v2:** los PINs pasaron a guardarse hasheados; la migración re-hashea los PINs
  en claro de instalaciones existentes para que el login siga funcionando.
- **v6:** al empezar a forzar foreign_keys, una instalación vieja podría tener
  filas huérfanas de cuando no se validaban. No se borran a ciegas: se corre
  `PRAGMA foreign_key_check` y se dejan en el log para revisión manual (no bloquea
  el arranque).
- **v7:** insumos y recetas (activable, default OFF). **v8:** envío por zona.
  **v9:** teléfono/dirección del cliente para la comanda de reparto.

Las migraciones de datos corren solas al abrir; el módulo de actualizaciones
(`docs/actualizaciones.md`) no toca los datos.
