# Soft delete de órdenes y cortes

Permite **eliminar** una orden o un corte Z sin borrarlo de la base: el registro
queda guardado pero se **oculta** de las listas, los reportes y los cortes. Nace
del uso en sitio: tras hacer pruebas quedaban órdenes y un corte de prueba
contando en los reportes, y no había forma de quitarlos (cancelar no basta:
`cancelado` sí se sigue mostrando).

## Distinto de cancelar

- **Cancelar** (orden): `status = 'cancelado'`, `paymentStatus = 'cancelado'`,
  con motivo. La orden **sigue visible** (en el historial, marcada como
  cancelada) — es parte del registro del día.
- **Eliminar** (soft delete): marca `deletedAt` y la orden/corte **desaparece**
  de todo lo operativo. Se usa para limpiar pruebas o errores.

## Modelo

Columna `deletedAt` (DateTime nullable) en `Orders` y `Shifts` (migración v11).
`null` = vigente; con fecha = eliminado.

Se excluye `deletedAt IS NULL` en:

- **Órdenes:** `getActiveOrders`, `getActiveOrdersWithItems`,
  `watchActiveOrders`, `getOrdersByDateRange`, `getOrdersByShift`
  (`OrdersDao`). `getOrderById` **sí** la devuelve (para auditoría).
- **Reportes:** todas las agregaciones de `ReportsDao` (ingresos, conteo, top
  productos, por categoría, por empleado, y por método de pago — este último
  con JOIN a `orders` para excluir los pagos de órdenes eliminadas).
- **Cortes:** `getClosedShifts`, `getShiftsByEmployee`, `getCurrentOpenShift`
  (`ShiftsDao`). `getMaxZNumber` **cuenta también los eliminados**: el número Z
  no se reutiliza.

## Seguridad

Ambas acciones exigen **PIN de supervisor** (`PermissionAction.eliminar`, como
cancelar/reembolsar) y quedan en `audit_log` (entidad `order`/`shift`).

## Dónde vive en la UI

- **Órdenes** (`orders_screen.dart`): detalle de la orden → "Eliminar".
- **Cortes** (`shifts_screen.dart`): detalle del corte Z → "Eliminar corte".

No hay pantalla de "papelera" para restaurar; el registro queda en la BD por si
se necesita recuperarlo manualmente.
