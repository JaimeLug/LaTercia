# Inventario e insumos

Código en `lib/core/database/daos/inventory_dao.dart`. Un producto puede rastrear
stock de **dos formas mutuamente excluyentes**:

- **Stock simple** (`trackInventory`): se descuenta 1:1 la cantidad vendida del
  `stockQuantity` del propio producto.
- **Receta / insumos** (`usesRecipe`, requiere el sistema de insumos activo —
  Settings `insumos_activo`): al vender, se descuenta cada insumo de la receta
  (`recipe_items`) multiplicado por la cantidad de producto. Materia prima en
  `ingredients`, con cantidades en `real` para unidades fraccionarias (g, ml);
  la `unit` es texto libre, sin conversión entre unidades (decisión de diseño).

## Punto único de descuento

`decrementForSale` (y su espejo `incrementForSale` para
cancelaciones/anulaciones/reembolsos) es el **único** lugar que decide entre
receta y stock simple, para que los call sites de venta (checkout, enviar a
cocina) no dupliquen esa decisión. Si el sistema de insumos está apagado o el
producto no tiene receta, cae al descuento de stock simple de siempre.

Cada entrada/salida se registra como movimiento (`inventory_movements` para
productos, `ingredient_movements` para insumos), así el historial de stock queda
auditado. Solo se afectan los productos que rastrean inventario.
