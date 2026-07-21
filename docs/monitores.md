# Monitores

Sección de Configuración para **ver y nombrar** los monitores conectados, y usar
esos nombres al abrir la Cocina. Nace del feedback en sitio (2026-07): el cliente
no sabía cuál "Pantalla 1/2" era cuál y tuvo problemas al abrir el KDS en la
pantalla equivocada (ver `kds.md` §"Abrir en otra pantalla").

## Alcance

- **Ver** los monitores con su **nombre real del sistema** (conector: `DP-1`,
  `HDMI-1`, …), resolución actual, posición y si es el principal.
- **Renombrar**: ponerle a cada monitor un nombre amigable (ej. `DP-2` →
  "Cocina pared"). Se guarda por conector y se reutiliza en el selector de la
  Cocina.
- **Cambiar resolución** (solo Linux, vía `xrandr`) con **red de seguridad**:
  al aplicar se pregunta "¿se ve bien?" con cuenta regresiva de 15 s; si no se
  confirma, **revierte sola** a la anterior. La elegida se guarda y se
  **re-aplica al arranque** — pero solo si el modo sigue estando disponible
  (para no arriesgar un boot desatendido, donde no hay nadie que revierta).
- NO reposiciona monitores ni cambia cuál es el principal (eso queda para más
  adelante).

## De dónde salen los datos — `DisplayService`

`lib/core/services/display_service.dart`. Devuelve `List<MonitorInfo>`:

- **Linux** (el kiosco real): corre `xrandr --query` y lo parsea
  (`parseXrandr`, función pura y testeada). De cada línea `<conector> connected
  [primary] <W>x<H>+<X>+<Y>` saca conector, resolución, posición y si es el
  principal.
- **Windows/otros** (desarrollo): cae a `screen_retriever`
  (`getAllDisplays()`), mapeado al mismo `MonitorInfo`.

`MonitorInfo.id` = el conector en Linux (clave estable para guardar el nombre) o
el id de `screen_retriever` en otros SO.

## Nombres amigables

Se guardan en `settings` bajo la llave `monitor_nombres` como JSON
`{ "<id>": "<nombre>" }`. Vacío = se muestra el nombre del sistema. El helper
vive en `DisplayService` (`nombresGuardados` / `guardarNombre`).

## Uso en el selector de la Cocina

`kds_launcher.dart` usa `DisplayService.list()` (no `screen_retriever` directo):
lista los monitores **secundarios** (nunca el principal, para no tapar el POS —
ver `kds.md`) con su nombre amigable si lo tiene. Al elegir uno, lanza el KDS en
su posición/tamaño.

**Supuesto de escala:** se usan los píxeles de `xrandr` (físicos) para
posicionar la ventana. En el kiosco (TV a resolución nativa, escala 1×) coinciden
con los lógicos; si algún día se usa escala ≠ 1×, habría que convertir.

## Dónde vive en la UI

- Configuración → tarjeta **"Monitores"** → `MonitoresScreen`
  (`lib/features/admin/screens/monitores_screen.dart`): lista + campo de nombre
  por monitor + botón "Actualizar".
