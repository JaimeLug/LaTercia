# Promociones programadas

Extiende los **Descuentos** que ya existían (`Discounts`, `docs/precios-e-iva.md`
§Descuentos) con dos cosas nuevas: una **ventana de día/hora** (happy hour) y un
tipo **2x1**, con **aplicación automática** en el POS cuando corresponde. Nace
del roadmap de módulos (2026-07-21): "el más barato de construir" porque
reutiliza toda la tabla y la lógica de elegibilidad que ya había.

## Modelo (migración v13)

Cuatro columnas nuevas en `Discounts`, todas nullable = sin restricción:

- `daysOfWeek` — CSV de días ISO (`1`=lunes … `7`=domingo, igual que
  `DateTime.weekday`). `null`/vacío = todos los días.
- `startTime` / `endTime` — hora del día en `"HH:mm"` (24h). Los dos deben
  estar presentes para que exista ventana; si falta uno, no hay restricción de
  hora. Soporta ventanas que cruzan medianoche (`22:00`–`02:00`).
- `productScope` — CSV de nombres de **producto** (no de categoría — cambiado
  tras feedback de sitio 2026-07-22: interesa más un "2x1" sobre un producto
  específico que sobre toda una categoría), case-insensitive, vacío = aplica
  a todos. Se reutiliza el selector compartido `CategoryScopePicker`
  (`lib/features/admin/widgets/category_scope_picker.dart`, ahora
  parametrizado con un `title` para poder mostrarse como selector de
  productos sin renombrar el widget — sigue sirviendo tal cual para
  `Modifiers.categoryScope`, que ese sí es por categoría).

`type` ahora acepta un tercer valor: `'2x1'` (además de `'percentage'` y
`'fixed'`).

## Elegibilidad (`isDiscountEligible`, `lib/core/utils/pricing.dart`)

Todas las condiciones son independientes y se combinan con AND (igual que ya
pasaba con `active`/`validFrom`/`validUntil`/`minOrderAmount`):

- Si hay `daysOfWeek`, el día de hoy debe estar en la lista.
- Si hay ventana de hora completa (`startTime` y `endTime`), la hora actual
  debe caer dentro (soporta cruce de medianoche).
- Un dato de horario **mal formado** (p.ej. `"25:99"`) hace que la promoción
  **no** sea elegible — falla cerrado, para no aplicar una promo con datos
  rotos sin que nadie se entere. En la práctica no pasa: se captura con
  `showTimePicker`, nunca texto libre.

`isScheduledDiscount(d)` — `true` si tiene `daysOfWeek` o ventana de hora. Es
lo que distingue una promoción programada (happy hour) de un descuento manual
de mostrador (ej. "Cliente frecuente 10%"): solo las programadas se
**auto-aplican**.

## Monto del descuento sobre el carrito (`discountAmountForCart`)

`discountAmountFor(d, subtotal)` (la función vieja) sigue existiendo tal cual —
nadie la tocó, sigue cubriendo el caso simple de todo el carrito. La nueva
`discountAmountForCart(d, lines)` la envuelve para soportar alcance de
producto y 2x1:

1. Filtra `lines` (`PromoLine`: `unitPrice`, `quantity`, `productName`) al
   `productScope` de `d` (vacío = todos).
2. Si `type == '2x1'`: por cada línea filtrada, `quantity ~/ 2` unidades salen
   gratis (redondeo hacia abajo: 3 unidades → 1 gratis, no 1.5).
3. Si no, aplica `discountAmountFor` sobre el subtotal **de las líneas
   filtradas** (no de todo el carrito) — con `productScope` vacío esto es
   exactamente el subtotal completo, o sea 100% compatible con el
   comportamiento de antes.

**Nota de alcance (v1):** el 2x1 se calcula **por línea del carrito**, no
cruzando productos distintos (p.ej. "2 cafés americanos" cuenta, "1 café + 1
té" no). Es la implementación honesta más barata; cruzar productos dentro de
una categoría queda para una fase 2 si hace falta.

## Aplicación automática en el POS

En `pos_screen.dart`, cuando el carrito cambia y **no hay un descuento ya
elegido a mano**, si existe una promoción `isScheduledDiscount` elegible, se
selecciona sola (mismo mecanismo que ya usaba el `WidgetsBinding
.addPostFrameCallback` para *quitar* un descuento que dejó de calificar).

El cajero conserva el control: tocar el pill **"Sin desc."** la descarta para
el resto de esa orden (`_autoDismissed`), sin que se vuelva a auto-aplicar
hasta la siguiente orden (`_clearCart` resetea el flag). Los pills de
promociones programadas llevan un ícono de reloj para que el cajero entienda
por qué salió sola.

El total real se calcula igual de siempre: `discountAmountForCart` resuelve el
monto en efectivo, y ese monto se pasa a `computeTaxedTotals` como si fuera un
descuento `'fixed'` ya resuelto — así el prorrateo de IVA existente
(`docs/precios-e-iva.md`) no se toca para nada.

## Dónde vive en la UI

- **Configuración → Descuentos** (`discounts_screen.dart`): el formulario
  ahora tiene el tipo `2x1`, chips de día de la semana, selector de hora
  inicio/fin, y el selector de **producto** compartido. La lista muestra la
  vigencia programada cuando aplica.
- **POS** (`pos_screen.dart`): los pills de descuento junto al resumen del
  carrito, en una barra horizontal con scroll (mismo patrón de auto-scroll
  que la barra de categorías — con más de 3 descuentos activos, el elegido
  se centra solo; feedback de sitio 2026-07-22, antes el 3er+ pill quedaba
  fuera de vista sin forma de llegar a él). El programado se auto-selecciona
  y se puede quitar igual que cualquier otro.
