# Modo kiosko: energía y reinicio

En modo kiosko no hay escritorio ni menú del sistema a la vista, así que apagar,
reiniciar el equipo o reiniciar solo la app se hace **desde la propia aplicación**
(pantalla de Quiosco). Código en `lib/core/utils/power_service.dart`.

Todo es best-effort: devuelve `true` si el comando arrancó; nunca lanza.

## Apagar / reiniciar el equipo

Estrategia por plataforma:

- **Windows:** `shutdown /s /t 0` (apagar) o `shutdown /r /t 0` (reiniciar).
- **Linux:** `systemctl poweroff` / `systemctl reboot` (una sesión local activa
  suele estar autorizada por polkit sin contraseña). Si eso falla, cae al
  `shutdown -h now` / `shutdown -r now` clásico.
- Otras plataformas: no soportado (se loguea y devuelve `false`).

## Reiniciar solo la app

`restartApp()` relanza un proceso nuevo (detached, para que sobreviva al actual
cerrando) y termina el proceso actual. Útil tras cambios de configuración o si la
app se ve rara, sin esperar un reinicio completo del sistema. No retorna.
