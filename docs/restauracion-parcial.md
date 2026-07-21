# Restauración parcial por grupo (asistente de fusión)

Restaurar **solo una parte** de la base desde un `.db` (solo Clientes, solo
Catálogo, etc.) sin tocar el resto. Código en
`lib/core/services/backup_service.dart` (`previewGroupRestore` /
`applyGroupRestore`) y la pantalla Admin → Backups. El `.db` elegido se abre en
**solo lectura** con el paquete `sqlite3` (archivo aparte de la base viva).

## Grupos seguros

Solo se restauran por partes los **datos maestros** (autocontenidos o que solo
referencian a otros datos maestros): **Catálogo, Clientes, Empleados, Inventario**
(proveedores/ingredientes/recetas) **y Envío**.

Quedan **fuera** a propósito (solo se restauran con el `.db` completo):

- **Operación** (turnos, órdenes, pagos, gastos, reembolsos, movimientos de
  caja): historial real de negocio, ligado a casi todo — restaurarlo a medias
  mientras el resto sigue vivo es justo donde se corrompen los datos.
- **Movimientos de inventario/ingredientes y compras**: historial transaccional
  (referencian órdenes), mismo motivo.
- **Sistema** (settings, audit_log): restaurar settings pisaría en silencio la IP
  de la impresora / IVA actuales; el audit_log es append-only.

## Comparación (`previewGroupRestore`)

Compara fila por fila **por `id`** el `.db` elegido contra la base actual, y
clasifica cada fila del respaldo:

- **`nueva`**: el id no existe en la base actual → se agrega sin preguntar.
- **`igual`**: existe y todas las columnas coinciden → nada que decidir.
- **`diferente`**: existe pero cambió alguna columna → el usuario decide.

## Aplicar (`applyGroupRestore`)

Todo en una transacción de drift.

### Modo Reemplazar

Borra el grupo completo (en orden inverso por las llaves foráneas) e inserta lo
del respaldo. Si una fila que se borra **sigue referenciada desde fuera** del
grupo (ej. un producto con ventas), la FK lanza y la transacción **revierte
completa** — la base queda igual que antes. Esa es la red de seguridad.

### Modo Agregar / fusionar

No borra nada. Agrega las `nueva`, mantiene las `igual`, y para las `diferente`
aplica lo que el usuario resolvió **columna por columna**:

- El asistente expande cada fila distinta y, por cada campo que cambió, muestra el
  valor **Actual** y el del **Respaldo** para elegir; hay atajos "Todo actual" /
  "Todo respaldo" por fila.
- La fila final puede quedar **mezclada** (unos campos de la actual, otros del
  respaldo). La UI la arma y la pasa como `resolvedRows` (`'tabla:id'` → mapa de
  valores finales); un conflicto sin entrada se mantiene tal cual.

Devuelve un conteo: cuántas se **agregaron**, **actualizaron** y **mantuvieron**.
