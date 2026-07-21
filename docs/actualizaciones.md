# Versionado y actualizaciones

El detalle operativo del módulo de actualizaciones (aplicar un paquete desde USB,
swap atómico, rollback) está en el manual de instalación
(`linux_kiosk/MANUAL_ZERO_TO_PRODUCTION.md`, Fase 6) y en el plan
(`PLAN_ACTUALIZACION_GRANDE_2026-07.md`, §7). Aquí solo las reglas de código.

## Versión instalada

`appVersion` en `lib/core/utils/app_version.dart` es la **fuente única de verdad**
de la versión que corre. Debe subirse a mano junto con `version:` en
`pubspec.yaml` en cada release — no hay forma cero-dependencias de leer el propio
pubspec en runtime sin agregar `package_info_plus`.

## Comparar versiones

`compareVersions("1.2.0", "1.10.0")` compara **componente a componente**, no como
texto:

- `"1.10.0"` es **mayor** que `"1.9.0"` (aunque como texto `"1.10.0" < "1.9.0"`).
- Componentes faltantes cuentan como 0: `"1.2" == "1.2.0"`.
- Ignora cualquier sufijo no numérico tras el primer no-dígito de cada
  componente: `"1.2.0-beta"` se compara como `"1.2.0"`.
- Devuelve `<0` si `a < b`, `0` si son iguales, `>0` si `a > b`.

## Motor de actualización (`UpdateService`)

Código en `lib/core/services/update_service.dart`. Es **manipulación de archivos
pura, sin nada de Flutter/UI**, para poder probarlo de punta a punta con
directorios temporales (sin una instalación real ni estar en Linux) y para poder
correrlo también como script (`dart run tool/generate_update_manifest.dart`).

### El paquete y su manifiesto

Un paquete de actualización trae el bundle + un `update_manifest.json` con la
**versión** y el **sha256 de cada archivo**, para verificar integridad **antes**
de aplicar nada.

- `generateManifest` se corre **una vez**, al preparar el paquete (no en la
  máquina que lo recibe). Normaliza los separadores de ruta a `/` para que el
  manifiesto sea idéntico se haya generado en Windows (dev/VM) o Linux.
- `verifyPackage` recalcula el checksum de cada archivo listado y devuelve las
  rutas que no coinciden o faltan (vacío = íntegro). Es solo lectura.
- Un paquete sin manifiesto válido **nunca** se aplica.

### Aplicar (swap atómico con rollback)

`applyUpdate(packageDir, installDir)`:

1. Verifica integridad (checksum de CADA archivo). Si algo no cuadra, aborta sin
   tocar `installDir`.
2. Copia el paquete a una carpeta de *staging* en el **mismo volumen** que
   `installDir` (el USB puede estar en otro volumen; copiar ahí no es atómico,
   pero todavía no toca la instalación viva).
3. Verifica la copia otra vez (defensa en profundidad).
4. Respalda `installDir` con un **rename** (atómico, mismo volumen) a
   `<installDir>.backup-<timestamp>`.
5. Renombra el staging a `installDir` (rename atómico).
6. Si el paso 5 falla, restaura el backup automáticamente — **nunca** deja la PC
   sin una app funcional.

Si algo falla **antes** del paso 4, `installDir` no se toca en absoluto. El
timestamp del backup lo identifica y decide el orden para el rollback (se
incrementa hasta no chocar con uno existente).

### Revertir (`rollback`)

Restaura `installDir` al respaldo `<installDir>.backup-<timestamp>` **más
reciente** que exista junto a él. Para deshacer una actualización problemática
después del hecho. Aparta la instalación actual antes de restaurar, y si la
restauración falla, la vuelve a poner.
