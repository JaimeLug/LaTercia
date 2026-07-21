# Estándar de trabajo — cómo ordenamos y documentamos La Tercia

Cómo se construye y se mantiene este proyecto. **Todo módulo nuevo se hace así
desde el principio** (no "primero funciona y luego se limpia"): documentado y
ordenado desde la primera línea.

## 1. Documentación (`docs/`)

- La explicación **larga** (reglas de negocio, decisiones de diseño, "por qué")
  vive en un `.md` de `docs/`, **un archivo por dominio** (ej. `precios-e-iva.md`,
  `impresion.md`, `ordenes-y-cocina.md`).
- Cada archivo nuevo se agrega al índice `docs/README.md` (una línea).
- En el **código** quedan doc-comments (`///`) **muy cortos**: idealmente solo el
  puntero al `.md` (ej. `/// docs/precios-e-iva.md §Descuentos.`), o una frase
  mínima + puntero. Nada de párrafos largos en el código.
- Los comentarios **inline** cortos que ayudan a leer una fórmula/algoritmo justo
  ahí **se dejan**.
- **Todo en español.** Nada de comentarios en inglés.
- Sin marcas históricas de fase ("FASE 4.5", fechas) en los comentarios nuevos —
  eso va, si acaso, en el `.md` o en el historial de git.

## 2. Organización del código

- **Lógica de negocio en servicios puros** (`lib/core/services/…`), sin UI, para
  poder probarla aislada. La UI (pantallas/widgets) queda delgada: llama al
  servicio y pinta.
- El cálculo de dinero, impuestos, snapshots, etc. **nunca** en el widget.
- Operaciones que tocan varias tablas → **una transacción de drift**
  (all-or-nothing).
- Trabajar **archivo por archivo**: leer el archivo completo antes de editar.

## 3. Base de datos (Drift)

- Cambio de esquema = **nueva migración** en `onUpgrade` + subir `schemaVersion`.
  La migración corre sola al abrir y **no debe perder datos** (probarlo).
- Cada bloque `if (from < N)` documenta su propio paso en el código (ahí sirve).
- Datos que deben quedar **congelados** (precio, IVA, claves al momento de la
  venta) se guardan como **snapshot inmutable**, no se recalculan después.
- Diseño general y multiproceso: `docs/base-de-datos.md`.

## 4. Puertas de calidad (antes de dar algo por terminado)

1. `flutter analyze` **limpio** (sin issues nuevos).
2. **Tests con dientes**: que fallen si se revierte el fix/feature. Para lógica
   pura, tests de servicio; para pantallas, widget tests. Verificar que pasan.
3. `dart format` sobre los archivos tocados.
4. Para cambios grandes o de plataforma: `flutter build windows --debug`
   (o el target que aplique) exitoso.
5. Correr la **suite completa** al cerrar un lote, no solo el test del archivo.

## 5. Git

- Ramas por feature/fix cuando aplique.
- **Commits dedicados**: no mezclar un bug fix con una feature con la limpieza.
  Cada cosa su commit (se puede stagear selectivamente).
- Mensajes de commit claros: qué cambió y por qué, no solo el "qué".

## 6. Para un módulo NUEVO (checklist de arranque)

1. Crear su `docs/<modulo>.md` con el diseño y las decisiones **antes/mientras**
   se programa (no después).
2. Diseñar el modelo de datos pensando en el futuro (que no falten campos).
3. Migración Drift + `schemaVersion`.
4. Servicio(s) puros con la lógica; UI delgada encima.
5. Tests con dientes conforme se avanza.
6. Punteros cortos en el código → `docs/<modulo>.md`.
7. Agregar el tema al índice `docs/README.md`.
8. Puertas de calidad (§4) antes de entregar.
