# Combos / paquetes

Paquetes de productos a precio especial (ej. "Combo Desayuno: café + pan,
$45"). Nace del roadmap de módulos (2026-07-21).

## Decisión de diseño: un combo se EXPANDE, no es un concepto nuevo en la orden

Un combo **no** es una entidad nueva a lo largo del sistema — al agregarlo al
carrito se **expande en sus productos reales** (uno por componente, con la
cantidad configurada), igual que si el cajero los hubiera agregado sueltos. Eso
significa que **todo lo demás sigue funcionando sin tocarlo**:

- **Inventario**: `decrementForSale` descuenta por `productId` sin importar si
  la línea vino de un combo o no.
- **Comanda de cocina / KDS**: ya listan por `productName`/`quantity`; el
  barista ve "1× Café Americano, 1× Pan de elote" tal cual, sin cambios.
- **Modificadores**: cada componente pasa por el mismo selector de
  modificadores que si se vendiera solo (si el producto tiene modificadores
  configurados para su categoría).

Solo el **carrito** necesita saber que un grupo de líneas pertenece a un combo
(para agruparlas visualmente). **El ticket impreso NO se toca**: cada producto
sale con su precio prorrateado, tal cual como cualquier otra venta — y como el
prorrateo hace que la suma cuadre exactamente con el precio del combo, el
ticket es igual de correcto sin tocar `print_service.dart` (código de
impresión delicado, en producción activa). Si más adelante se quiere un
encabezado "COMBO" en el ticket, es un cambio aislado y opcional.

## Modelo (migración v14)

- **`Combos`**: `id`, `name`, `price` (precio fijo del paquete), `active`,
  `createdAt`.
- **`ComboItems`**: `id`, `comboId` → `Combos`, `productId` → `Products`,
  `quantity` (cuántas unidades de ese producto trae el combo).
- **`OrderItems`** gana dos columnas nullable: `comboInstanceId` (un id
  generado por el POS — `Uuid().v4()` — que comparten todas las líneas de
  **una** compra de combo; permite pedir el mismo combo dos veces en la misma
  orden sin que se mezclen) y `comboName` (denormalizado, mismo patrón que
  `productName` — el ticket no necesita volver a consultar `Combos`).

## Reparto del precio (`proratedComboPrices`, `lib/core/utils/pricing.dart`)

El precio fijo del combo se reparte entre sus componentes **proporcional al
precio normal de cada uno** (× su cantidad) — así un componente más caro
absorbe más del "descuento" implícito del paquete, y la suma de las líneas da
exactamente el precio del combo:

```
factor = precioCombo / Σ(precioNormal × cantidad)
precioLínea = precioNormal × factor
```

Si la suma de precios normales es 0 (productos sin precio o combo vacío), se
reparte en partes iguales para no dividir entre cero.

**Los modificadores se cobran aparte, encima del prorrateo** — si el cajero
agrega "extra shot" a un café dentro de un combo, ese extra se suma normal (el
combo no lo regala). Se logra vía `product.copyWith(price: precioLínea)`
(mismo `id`, misma categoría — todo el resto del producto real intacto — solo
cambia el precio base) pasado al `CartItem` normal, así `unitPrice` sigue
calculándose igual que siempre (`price + deltas de modificadores`).

## En el carrito (POS)

Las líneas de un mismo `comboInstanceId` se muestran **agrupadas bajo un
encabezado** ("Combo: Desayuno — $45"), sin precio individual por línea ni
selector de cantidad (la cantidad de cada componente viene fija del combo). El
botón ✕ del grupo quita **todas** sus líneas juntas — nunca queda un combo a
medias.

Tocar el combo otra vez en el catálogo agrega **otra instancia completa**
(nuevo `comboInstanceId`) — no hay "cantidad de combos" que escale, para
mantener la lógica simple y correcta (evita la pregunta ambigua de qué
significa "+1" sobre un paquete de 2 productos distintos).

Si el cajero cancela el selector de modificadores de **cualquier** componente
a medio combo, se aborta el combo completo — no se agrega nada parcial.

## Dónde vive en la UI

- **Configuración → Combos** (`combos_screen.dart`): lista + formulario
  (nombre, precio, componentes con producto+cantidad).
- **POS**: chip **"Combos"** en la barra de categorías (solo aparece si hay
  combos activos) que cambia la cuadrícula de productos por tarjetas de combo.
