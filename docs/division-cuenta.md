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
   sigue siendo honesta.
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

## Dónde vive en la UI

- **Partes iguales**: dentro del `PaymentModal` de siempre — un botón
  "Dividir cuenta" arriba (solo antes de agregar el primer tramo) pide el
  número de personas y precarga el monto de cada parte.
- **Por artículo**: botón **"Dividir por artículo"** en la barra de resumen
  del carrito del POS, junto a "Cobrar". Deshabilitado si el carrito tiene
  menos de 2 líneas o si hay un descuento/combo/recompensa aplicado.
