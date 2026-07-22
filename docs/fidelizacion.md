# Fidelización

Recompensa a clientes recurrentes. Nace del roadmap de módulos (2026-07-21).
Dos mecánicas disponibles — **el dueño elige cuál usar** (no corren las dos a
la vez para el mismo cliente): **sellos** (tarjeta de puntos física: cada N
visitas, la siguiente trae un producto gratis) o **puntos** (acumulan por lo
gastado, canjeables al llegar a un umbral).

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

**`Settings`** (tabla clave-valor genérica, sin migración) gana 5 llaves:

| Llave | Significado |
|---|---|
| `loyalty_type` | `'ninguno'` (default) \| `'sellos'` \| `'puntos'` |
| `loyalty_stamps_required` | Sellos para ganar la recompensa (ej. `10`) |
| `loyalty_points_per_currency` | Pesos gastados por 1 punto (ej. `10` = 1 punto cada $10) |
| `loyalty_points_required` | Puntos para poder canjear (ej. `100`) |
| `loyalty_reward_category` | Categoría de la que sale el producto gratis |

## Ganar (al pagar una venta)

`CustomersDao.earnLoyalty(customerId, amountSpent)` — se llama **junto a**
`incrementVisits`, en los mismos dos puntos donde ya se llamaba
(`CheckoutService.checkout` y `.chargeExistingOrder`). Lee los settings del
propio `AppDatabase` (`attachedDatabase.settingsDao`, mismo patrón que ya usa
`InventoryDao` para `insumos_activo`) — no hace falta pasarlos como parámetro:

- `'sellos'`: +1 sello por cada venta pagada con cliente vinculado (igual que
  `visits`).
- `'puntos'`: `+ (amountSpent / loyalty_points_per_currency).floor()`.
- `'ninguno'`: no hace nada.

## Canjear (al cobrar, si el cliente calificó)

`loyaltyRewardAvailable(...)` (pura, `lib/core/utils/pricing.dart`) dice si el
cliente seleccionado ya junta lo suficiente. Si sí, en el POS aparece un pill
**"🎁 Recompensa disponible"** (el cajero lo activa a mano — **no se
auto-aplica**, a diferencia de las promociones programadas: regalar algo debe
ser una decisión consciente del cajero, no automática).

`loyaltyRewardAmount(lines, category)` (pura) calcula el monto: el precio del
producto **más caro** de la categoría premiada que haya en el carrito (0 si no
hay ninguno de esa categoría — el pill no debería mostrarse en ese caso). Ese
monto se suma al descuento resuelto de la promoción elegida (si hay una) y se
pasa a `computeTaxedTotals` como un `Discount` `'fixed'` ya calculado — mismo
mecanismo que ya usan Promociones y Combos, el prorrateo de IVA no se toca.

`CustomersDao.redeemLoyalty(customerId, wasStamps)` resetea `loyaltyStamps` a
0 o resta `loyalty_points_required` de `loyaltyPoints`. Se llama **solo** si
la venta se cobra de una vez (`CheckoutService.checkout`, no en el flujo de
"enviar a cocina y cobrar después") — para no quemarle el sello/los puntos a
un cliente si la venta termina cancelada antes de pagarse. **v1 no soporta
canjear en una orden que se paga después** (limitación conocida, ver
"Fuera de alcance").

## Dónde vive en la UI

- **Configuración → Ventas → Fidelización** (categoría dentro de la pantalla
  de Configuración, no una pantalla aparte — son 5 campos): tipo de programa,
  umbral, tasa de puntos, categoría premiada.
- **POS**: el campo de cliente (ya existía, antes texto libre) ahora también
  busca coincidencias (`CustomersDao.searchCustomers`, debounce 250 ms) y dan
  a elegir un cliente real. Al seleccionar uno, se muestra su progreso ("Ana —
  7/10 sellos") y, si califica, el pill de recompensa.

## Fuera de alcance (v1)

- Crear un cliente nuevo desde el buscador del POS (hoy solo busca/selecciona
  existentes; crear clientes sigue siendo desde Configuración → Clientes).
- Canjear en una orden de "pagar después" (`chargeExistingOrder`).
- Correr las dos mecánicas (sellos y puntos) a la vez, o por cliente.
