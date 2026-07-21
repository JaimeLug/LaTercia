# Seguridad y PINs

## PINs de empleados

Los PINs se guardan **hasheados, nunca en texto plano**. Código en
`lib/core/utils/pin_hasher.dart`.

- **Esquema:** un *pepper* constante de la aplicación + SHA-256
  (`hashPin(pin) = sha256('latercia::pin::v1' + pin)`).
- **Por qué sin salt por registro:** los PINs son cortos (4 dígitos, ~10 000
  combinaciones), así que un salt por registro aportaría poco contra fuerza
  bruta. El objetivo real aquí es que la base **nunca contenga un PIN legible**.
- **Por qué determinista:** al ser el mismo hash siempre para el mismo PIN, el
  login sigue siendo una simple consulta de igualdad, y la restricción
  `UNIQUE(pin)` (dos empleados no pueden compartir PIN) sigue funcionando.

`isDefaultAdminPin` detecta si un PIN guardado es el del admin sembrado por
defecto (`0000`), para insistirle al operador que lo cambie.

## Nunca loguear PINs

La columna `Employees.pin` (ni el PIN en claro) debe entrar **jamás** a un
mensaje de log o a un objeto de error. Ver `docs/logs.md`.
