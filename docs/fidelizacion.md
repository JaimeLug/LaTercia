# Fidelización

Recompensa a clientes recurrentes. Nace del roadmap de módulos (2026-07-21).
Dos mecánicas, **independientes entre sí** — el dueño puede activar sellos,
puntos, o los dos a la vez para el mismo cliente (v1 los tenía como
mutuamente excluyentes; corregido tras feedback de sitio 2026-07-22, ver
"Historial de cambios" abajo): **sellos** (tarjeta de visitas: cada N ventas,
la siguiente trae un producto gratis) o **puntos** (cada producto otorga los
puntos que el dueño le asigne; se acumulan y canjean por un producto al
llegar a un umbral).

## Requisito previo: el POS ya sabe quién compra

Antes de este módulo, el POS **nunca vinculaba la venta a un cliente real**
(`Orders.customerId` existía en el esquema, pero ningún flujo del POS lo
llenaba — solo había un campo de texto libre con el nombre). Sin saber
*quién* compra no hay manera de acumular sellos o puntos, así que este módulo
agrega también un **buscador de cliente** en el POS.

**Efecto colateral bueno:** `CustomersDao.incrementVisits` (que suma
`visits`/`totalSpent`) ya existía y ya se llamaba desde `checkout_service.dart`
cuando `customerId != null` — simplemente nunca se disparaba. Al agregar el
buscador, ese conteo **empieza a funcionar solo**, sin tocar esa lógica.

## Modelo

**`Customers`** gana dos columnas (migración v15):
- `loyaltyStamps` (entero, default 0) — sellos acumulados. Contador PROPIO,
  distinto de `visits` (que es un total histórico de por vida y no se debe
  resetear); `loyaltyStamps` sí se resetea al canjear.
- `loyaltyPoints` (entero, default 0) — puntos acumulados; al canjear se
  **resta** el umbral (no se resetea a 0 — el sobrante se queda).

**`Products`** gana una columna (también migración v15):
- `loyaltyPointsValue` (entero, default 0) — puntos que ESE producto otorga
  por unidad vendida. Editable desde Configuración → Fidelización (no desde
  la pantalla de Productos — el dueño pidió que viviera ahí, junto al resto
  de la configuración de puntos).

**`Settings`** (tabla clave-valor genérica, sin migración) gana 6 llaves:

| Llave | Significado |
|---|---|
| `loyalty_sellos_activo` | `'true'` \| `'false'` (default) — independiente de puntos |
| `loyalty_puntos_activo` | `'true'` \| `'false'` (default) — independiente de sellos |
| `loyalty_stamps_required` | Sellos para ganar la recompensa (ej. `10`) |
| `loyalty_points_required` | Puntos para poder canjear (ej. `100`) |
| `loyalty_stamps_reward_product` | Producto que se regala al canjear sellos |
| `loyalty_points_reward_product` | Producto que se regala al canjear puntos |

Las llaves viejas `loyalty_type`, `loyalty_points_per_currency` y
`loyalty_reward_category` quedaron obsoletas y ya no se leen ni se escriben.

## Ganar (al pagar una venta)

`CustomersDao.earnLoyalty(customerId, items)` — se llama **junto a**
`incrementVisits`, en `CheckoutService.checkout` (`chargeExistingOrder` sigue
sin soportarlo, ver "Fuera de alcance"). `items` es la lista de
`(productId, quantity)` de la orden — los puntos se calculan por producto, no
por monto total. Lee los settings del propio `AppDatabase`
(`attachedDatabase.settingsDao`, mismo patrón que ya usa `InventoryDao` para
`insumos_activo`):

- Si `loyalty_sellos_activo == 'true'`: +1 sello por cada venta pagada con
  cliente vinculado (igual que `visits`).
- Si `loyalty_puntos_activo == 'true'`: por cada línea de la orden, suma
  `producto.loyaltyPointsValue × cantidad` (una consulta a `ProductsDao` por
  línea).
- Ambas pueden dispararse en el MISMO cobro si las dos están activas.

## Canjear (al cobrar, si el cliente calificó)

`loyaltyRewardAvailable(...)` (pura, `lib/core/utils/pricing.dart`) dice si el
cliente seleccionado ya junta lo suficiente — se llama una vez por mecánica
activa. Si sí, en el POS aparece un pill **"🎁 Recompensa disponible"** por
cada mecánica calificada (el cajero lo activa a mano — **no se auto-aplica**,
a diferencia de las promociones programadas: regalar algo debe ser una
decisión consciente del cajero, no automática). Con sellos Y puntos activos,
pueden aparecer y aplicarse los DOS pills a la vez, de forma independiente.

`loyaltyRewardAmount(lines, productName)` (pura) calcula el monto: el precio
del producto premiado si está en el carrito (0 si no — el pill no debería
mostrarse en ese caso; antes tomaba el producto MÁS CARO de una categoría,
ahora el alcance es por producto específico, igual que Promociones).
Cada monto ganado (sellos y/o puntos) se suma al descuento resuelto de la
promoción elegida (si hay una) y se pasa a `computeTaxedTotals` como un
`Discount` `'fixed'` ya calculado — mismo mecanismo que ya usan Promociones y
Combos, el prorrateo de IVA no se toca.

`CustomersDao.redeemLoyalty(customerId, {stamps, points})` resetea
`loyaltyStamps` a 0 y/o resta `loyalty_points_required` de `loyaltyPoints` —
cada uno INDEPENDIENTE del otro (canjear sellos no toca los puntos y
viceversa). Se llama **solo** si la venta se cobra de una vez
(`CheckoutService.checkout`, no en el flujo de "enviar a cocina y cobrar
después") — para no quemarle el sello/los puntos a un cliente si la venta
termina cancelada antes de pagarse. **v1 no soporta canjear en una orden que
se paga después** (limitación conocida, ver "Fuera de alcance").

## Dónde vive en la UI

- **Configuración → Fidelización**: dos switches independientes (Sellos /
  Puntos), cada uno con su umbral y su producto de recompensa. Con Puntos
  activo, aparece además una lista con TODOS los productos y un campo
  editable de "puntos por unidad" para cada uno — se guarda en el mismo botón
  "Guardar cambios" de siempre (los puntos por producto viven en `Products`,
  no en `Settings`, así que se persisten aparte con
  `ProductsDao.updateLoyaltyPointsValue`, pero en la misma acción de guardar).
- **POS**: el campo de cliente (ya existía, antes texto libre) ahora también
  busca coincidencias (`CustomersDao.searchCustomers`, debounce 250 ms) y da a
  elegir un cliente real. Al seleccionar uno, se muestra su progreso por cada
  mecánica activa ("Ana — 7/10 sellos", "Ana — 45/100 puntos") y, si califica,
  el pill de recompensa correspondiente.

## Fuera de alcance (v1)

- Crear un cliente nuevo desde el buscador del POS (hoy solo busca/selecciona
  existentes; crear clientes sigue siendo desde Configuración → Clientes).
- Canjear en una orden de "pagar después" (`chargeExistingOrder`).
- Tarjeta de puntos física/escaneable (el dueño la pidió para una fase
  posterior — por ahora el cliente se selecciona a mano en el buscador).

## Historial de cambios

- **2026-07-22** (feedback de sitio): sellos y puntos pasaron de ser
  mutuamente excluyentes a independientes; la recompensa de sellos pasó de
  categoría a producto específico; el módulo de puntos se rediseñó para
  otorgar puntos POR PRODUCTO (`Products.loyaltyPointsValue`) en vez de una
  tasa fija de "pesos gastados por punto"; se quitó un texto de UI que
  filtraba una referencia a este mismo archivo (`docs/fidelizacion.md`) en
  la pantalla de Configuración.
