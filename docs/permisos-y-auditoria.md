# Permisos y auditoría

## Auditoría (bitácora de acciones sensibles)

`AuditService` (`lib/core/services/audit_service.dart`) es el envoltorio único
que usan todos los *hooks* de auditoría de la app para escribir en `audit_log`.

- Centralizar el insert aquí (en vez de llamar `db.auditLogDao.insertLog` por
  todos lados) mantiene el JSON-encoding de `detail` en un solo lugar y da a los
  puntos de llamada una API única y fácil de encontrar (greppable).
- **Nunca** pasar `Employees.pin` (ni un PIN en claro) dentro de `detail` —
  nada aquí lo limpia por ti. Ver `docs/seguridad.md`.

## Permisos por rol y PIN de supervisor

`PermissionService` (`lib/core/services/permission_service.dart`) controla las
acciones sensibles.

### Acciones sensibles (`PermissionAction`)

anular, descuento manual, abrir gaveta sin venta, corte Z, reimprimir, editar
catálogo, movimiento de caja, reembolso.

> La `key` de cada acción es el string estable que se guarda en
> `audit_log.action` y contra el que se comparan los tests. Es snake_case y **no
> debe renombrarse** una vez liberado, o las filas de auditoría viejas dejan de
> coincidir con las consultas nuevas.

### Matriz de permisos

- `admin` / `gerente` tienen **siempre** todos los permisos.
- Cualquier otro (en la práctica `cashier`) necesita que un **supervisor**
  (un empleado `admin`/`gerente` **distinto**) apruebe con su PIN.

### Validación del PIN de supervisor

`validateSupervisorPin` busca el PIN y verifica que pertenezca a un supervisor
distinto del que pide autorización. Puede fallar por tres razones (para que la
UI muestre un mensaje específico y no un genérico "PIN incorrecto"):

- **`invalidPin`**: ningún empleado activo tiene ese PIN.
- **`notSupervisor`**: el PIN es de un empleado, pero no es `admin`/`gerente`.
- **`sameEmployee`**: el PIN es del mismo empleado que pide autorización — un
  supervisor no puede aprobar su propia acción así.
