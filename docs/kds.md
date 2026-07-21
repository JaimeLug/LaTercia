# KDS (pantalla de cocina)

Comportamiento de la pantalla de cocina (Kitchen Display System) que se controla
con la botonera física del ESP32 (6 botones: 2 flechas, recall, preparación,
listo, tiempo). Código principal en `lib/features/kds/` y utilidades puras en
`lib/core/utils/kds_selection.dart` y `lib/core/utils/kds_modifiers.dart`
(separadas para poder probarlas sin montar widgets).

## Cursor de "tarjeta seleccionada"

La botonera opera siempre sobre una tarjeta seleccionada. La **selección
efectiva** (`effectiveSelection`) es:

- La selección actual, si sigue siendo una orden activa.
- Si no (nunca se eligió una, o la seleccionada ya salió de la lista), **la
  primera** de la lista.
- `null` solo si no hay ninguna orden activa.

**Por qué:** corrige el bug "el botón de prep/listo solo sirve una vez". Antes,
si la selección se perdía (p. ej. tras marcar "listo"), PREP/LISTO se volvían un
no-op silencioso hasta la siguiente pulsación de ANTERIOR/SIGUIENTE. Con esto
siempre hay una tarjeta operable, aunque nunca se haya navegado.

## Encadenar "listo, listo, listo"

Al marcar una orden como "listo" sale de la lista activa. La **siguiente
selección** (`nextAfterReady`) pasa a ser la que ocupaba la posición siguiente
(si era la última, se envuelve a la primera). Así la cocina puede encadenar
LISTO, LISTO, LISTO sin navegar entre cada una — el flujo natural de un bump bar.

## Modificadores en el KDS

Cada item de pedido guarda sus modificadores como JSON (`OrderItem.modifiersJson`).
`parseKdsModifiers` lo convierte en una lista de `KdsModifier` para mostrar, tanto
en las tarjetas como en la vista All-day (agregado 2026-07-20 para que
"sin azúcar"/"extra shot" también se vean en All-day).

- Cada modificador se muestra como `"Extra shot"` o `"Leche de almendra
  (incluido)"` según su flag `included`.
- El parseo **nunca lanza**: devuelve lista vacía si el JSON es nulo, vacío o
  inválido.
- La lista devuelta es **mutable** a propósito (`<KdsModifier>[]`, no
  `const []`): la vista All-day la ordena con `..sort(...)`, y un literal `const`
  lanzaría `Unsupported operation` al intentar mutarlo. (Este fue un bug real.)

## Pantalla y navegación (6 botones)

La cocina se opera **solo con la botonera** (sin mouse ni touch): 2 flechas,
recall, prep, listo, tiempo. Código en `lib/features/kds/kds_screen.dart`.

- **Cuadrícula de scroll continuo:** todas las órdenes activas viven en el mismo
  lienzo con scroll, en vez de páginas fijas. Antes "Siguiente" saltaba de golpe
  a otra "página" y las órdenes 5+ quedaban invisibles hasta darles clic; ahora
  avanzar es desplazarse, no saltar.
- **Tarjetas de alto automático:** cada tarjeta crece/encoge según su contenido,
  con un tope = alto de la pantalla; pasado el tope, la tarjeta hace scroll
  vertical interno (con flecha indicadora).
- **Anterior / Siguiente contextual:** si la tarjeta seleccionada tiene más
  contenido por ver en esa dirección (pedido largo), primero **desplaza** dentro
  de la tarjeta; recién cuando ya no queda más, **cambia de orden**. Para un
  pedido corto que cabe completo, cambia de orden directo. Así las 6 teclas
  bastan para todo (no había forma de bajar dentro de un pedido largo antes).
- **PREP / LISTO:** actúan sobre la tarjeta seleccionada. Siempre hay una
  selección operable si hay algo activo (si la selección se pierde, cae a la
  primera) — corrige el bug de "el botón solo sirve una vez". Tras LISTO, la
  selección **encadena** a la siguiente (cadencia de bump bar).
- **TIEMPO:** alterna la **vista All-day** (consolidada, "7× Frappé de Café").
  En All-day, Anterior/Siguiente **desplazan la lista** (no hay órdenes que
  cambiar ahí). Ver §"All-day".
- **RECALL:** deshace el último "listo" (ver §Recall / `docs/ordenes-y-cocina.md`).
- **Auto-rotación (tablero de pared):** cada 12 s se desplaza suave un lienzo
  hacia abajo (y vuelve al inicio al llegar al final), para un tablero sin tocar.
- **Selección visible:** al seleccionar con la botonera, el scroll trae la
  tarjeta a la vista (`Scrollable.ensureVisible`), para que no quede una orden
  "seleccionada" fuera de pantalla.

## All-day (vista consolidada)

Agrupa por producto + modificadores ("7× Frappé de Café", "3× Café sin azúcar"),
ordenado por lo más pedido, manteniendo juntas las variantes del mismo producto.
Los `ScrollController` por orden y de la All-day los posee `KdsScreen` (no cada
tarjeta) para poder leer/mover su posición desde la botonera.
