# División de cuenta

Dos mecánicas, elegidas por el cajero al momento de dividir (no es una
configuración fija). Nace del roadmap de módulos (2026-07-21) — Jaime mismo lo
marcó como el de menor prioridad ("más de nicho para un café de mostrador"),
así que el v1 se mantiene deliberadamente ligero.

## Partes iguales — reutiliza el pago mixto que ya existía

El modal de cobro (`PaymentModal`) **ya soportaba pagos mixtos** (varios
tramos, cada uno con su método, que se van sumando hasta cubrir el total —
`docs/ventas-cobro-turnos.md` §Pagos). Dividir en partes iguales es, en el
fondo, **la misma mecánica** con los montos precalculados: no crea órdenes ni
pagos nuevos en concepto, solo ayuda a que cada tramo salga del tamaño
correcto.

`splitEvenly(total, parts)` (pura, `lib/core/utils/pricing.dart`) reparte el
total en `parts` montos que **suman exactamente** el total a los centavos — el
sobrante de redondeo se le asigna a las primeras partes (ej. $100 entre 3 →
$33.34, $33.33, $33.33).

En el POS: botón **"Dividir cuenta"** → **"Partes iguales"** → pide el número
de personas → abre el `PaymentModal` de siempre, pre-cargando el monto de la
primera parte en el campo de "Recibido" (el cajero solo confirma/ajusta y le
da "Agregar", como ya hacía con un pago mixto manual). Sigue siendo **UNA
orden con varios pagos**, exactamente como ya funcionaba.

## Por artículo — cada persona termina con su propia orden

Aquí sí es un flujo nuevo, pero con una decisión de diseño que evita inventar
un concepto en el modelo de datos: **cada persona resulta en una orden
independiente**, generada llamando al `checkout()` que ya existe con un
subconjunto del carrito — como si fueran clientes separados pagando uno tras
otro. Eso significa que impresión, KDS e inventario **no se tocan**: ya saben
manejar una orden normal, sin importar que venga de un split.

1. El cajero toca **"Dividir cuenta" → "Por artículo"**.
2. Un diálogo lista las líneas del carrito; el cajero asigna cada línea
   COMPLETA a una persona (P1, P2, …) — **no se parte una línea por unidad**
   (ej. "2 cafés" no se puede repartir 1 y 1; si hace falta, se agregan como
   dos líneas separadas desde antes). Es la simplificación más barata que
   sigue siendo honesta. **Un combo es UNA sola unidad asignable, no varias**
   (`groupCartUnitsForSplit`, pura, en `pricing.dart`): sus líneas
   componentes SIEMPRE van juntas a la misma persona — prorratear el precio
   de un combo entre dos personas daba montos que no correspondían a "lo que
   cada quien pidió" (ej. $35.59 y $34.41 por un combo de $70, cuando en
   realidad cada componente cuesta distinto por separado); feedback de
   sitio 2026-07-22.
3. Al confirmar, se abre el `PaymentModal` de siempre **una vez por persona**,
   en secuencia — cada uno cobra solo lo suyo (subtotal/IVA calculados con
   `computeTaxedTotals` sobre ese subconjunto, la misma función pura de
   siempre) y genera su propio ticket.

## Fuera de alcance (v1)

- **Partes iguales SÍ convive con descuentos/promos/combos/recompensa** — no
  hay ambigüedad: reparte el TOTAL ya calculado (el que sea), no le importa
  cómo se llegó a él.
- **Por artículo NO prorratea descuentos, promociones, combos ni la
  recompensa de fidelización** — si el carrito tiene algo de eso aplicado, esa
  opción se deshabilita (con aviso de por qué). Prorratear eso por persona es
  una decisión de negocio con varias formas razonables de hacerse; mejor no
  adivinar. Partes iguales sigue disponible en ese caso.
- **Solo funciona en el cobro inmediato** (antes de "Enviar a cocina"). Dividir
  una orden que YA se mandó a cocina y se paga después no está soportado —
  movería líneas entre órdenes ya existentes, mucho más riesgoso.
- Partir una línea con cantidad > 1 entre dos personas (ver punto 2 arriba).

## Bugs encontrados en sitio (2026-07-22) y su arreglo

- **"Exacto" no cerraba el saldo con un total prorrateado de combo** (ej.
  $35.585): la comparación recibido-vs-saldo usaba una tolerancia fija de
  0.0001, insuficiente contra un residuo de medio centavo. Ahora
  `_isPartial`/`_closesBalance` comparan **en centavos enteros**
  (`_centsOf`/`_reachesCents` en `payment_modal.dart`), no en doubles crudos.
- **Cancelar a media persona borraba TODA la orden**: `_startItemSplit`
  llamaba `_clearCart()` sin importar si cada persona había pagado o
  cancelado. Ahora se rastrea qué grupos SÍ completaron el pago
  (`onCheckout` solo se dispara al confirmar, nunca al cancelar) y solo esas
  líneas se quitan del carrito — si alguien cancela, sus artículos se quedan.
- Cada `PaymentModal` del split por artículo ahora dice **"Cuenta de la
  persona N de M"** arriba del monto.
- **No se encontraba "partes iguales" desde el carrito**: el botón vivía
  escondido DENTRO del `PaymentModal` (solo tras tocar "Cobrar"), mientras
  que "por artículo" tenía su propio botón visible en el carrito — Jaime
  probó y solo encontró la segunda. Ahora el carrito tiene un solo botón
  **"Dividir cuenta"** que abre un diálogo con las dos opciones ("Partes
  iguales" / "Por producto"); elegir "Partes iguales" abre el `PaymentModal`
  con `autoStartEvenSplit: true`, que dispara de inmediato el mismo diálogo
  "¿Entre cuántas personas?" que antes había que buscar adentro.
- **Dividir por producto un combo seguía rechazando "Exacto"** incluso
  después del fix de centavos de arriba: `_checkoutGroup` (en
  `pos_screen.dart`) volvía a calcular el total del grupo **sin redondear**
  y ESE era el que se mandaba a `CheckoutService.checkout()`, mientras que
  el `PaymentModal` había mostrado/cobrado la versión YA redondeada a
  centavos — un total crudo como `$35.594` se ve como "35.59" en pantalla
  (igual que lo cobrado) pero es más alto que lo pagado, y `_assertCovers`
  (con su tolerancia fija de 0.001, insuficiente) lo rechazaba con "los
  pagos no cubren el total" aunque ambos números se vieran idénticos.
  Arreglado en dos capas: `_checkoutGroup` ahora redondea a centavos antes
  de pasar el total (igual que `_startItemSplit` ya hacía para mostrarlo), y
  `_assertCovers` también pasó a comparar en centavos enteros (mismo
  criterio que `_reachesCents` del `PaymentModal`) como defensa adicional.
- **Los recibos en pantalla se amontonaban uno sobre otro** al dividir entre
  3+ personas: `PaymentModal` mostraba su `ReceiptDialog` DESPUÉS de hacer
  `Navigator.pop` de sí mismo, así que `_startItemSplit` ya había abierto el
  `PaymentModal` de la siguiente persona antes de que el cajero alcanzara a
  cerrar el recibo de la anterior (feedback de sitio 2026-07-22). Arreglado
  quitándole a `PaymentModal` la responsabilidad de mostrar su propio recibo
  durante el split (`showReceiptOnConfirm: false`) — el ticket físico se
  sigue imprimiendo igual (no depende de ese diálogo); al terminar con
  TODAS las personas, `_startItemSplit` muestra un solo
  `_SplitReceiptsSummaryDialog` con la lista de órdenes cobradas y un único
  botón "Aceptar".

## Dónde vive en la UI

- **Botón "Dividir cuenta"** en la barra de resumen del carrito del POS,
  junto a "Cobrar" (visible con 2+ líneas) — abre un diálogo con las dos
  opciones:
  - **Partes iguales**: siempre disponible. Abre el `PaymentModal` con
    `autoStartEvenSplit: true`, que pide el número de personas y precarga el
    monto de cada parte (mismo mecanismo de pago mixto de siempre). También
    se puede iniciar desde DENTRO del `PaymentModal` normal (botón "Dividir
    cuenta" arriba, solo antes de agregar el primer tramo) — por si el
    cajero ya estaba cobrando y decide dividir a medio camino.
  - **Por producto**: deshabilitado si hay un descuento/combo/recompensa
    aplicado (con aviso de por qué). Abre `_SplitByItemDialog` para asignar
    cada línea a una persona.
