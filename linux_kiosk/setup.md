# La Tercia POS — kiosko Linux (Fase 6)

Guía para montar la app como kiosko que arranca sola al encender la PC. Probar
primero en una **máquina virtual Linux** (6.3) antes de la estación del cliente.

Recomendado: distro con Wayland y GNOME, o un compositor de una-sola-app como
`cage` (lo más "kiosko" posible).

---

## 1. Compilar

Requisitos de build de Flutter Linux (una vez). **Corre `apt update` primero**
(una VM recién instalada trae el índice de paquetes vacío):
```bash
sudo apt update
# Toolchain + GTK (build de escritorio):
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
# GStreamer -dev: lo necesita el plugin audioplayers para COMPILAR:
sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
# (opcional) plugins para REPRODUCIR los sonidos del KDS en runtime:
sudo apt install -y gstreamer1.0-plugins-base gstreamer1.0-plugins-good
flutter config --enable-linux-desktop
```
Ojo: nombres con **guion** antes de `dev` (`...1.0-dev`), y **sin** `\` de
continuación en una sola línea si copias a mano (evita paquetes mal partidos).

**Andamiaje de plataforma Linux (una vez):** el proyecto nació con runner de
Windows; hay que generar el de Linux (carpeta `linux/`). Ya está commiteado en
el repo, pero si `flutter build linux` dice *"No Linux desktop project
configured"*, genéralo con:
```bash
flutter create --platforms=linux .
```
Solo agrega `linux/` (runner GTK/CMake), no toca `lib/`. El binario se llama
`latercia`.

Compilar en release:
```bash
flutter build linux --release
# Bundle resultante: build/linux/x64/release/bundle/
```

Instalar el bundle:
```bash
sudo mkdir -p /opt/latercia
sudo cp -r build/linux/x64/release/bundle/* /opt/latercia/
# El binario queda en /opt/latercia/latercia
```

## 2. Datos, logs y backups en Linux

La app usa rutas estándar (path_provider), así que en Linux caen solas en:
`~/.local/share/latercia/` (base `latercia.db`, `logs/`, `backups/`,
`kds_endpoint.json`). No hay que configurar nada. **El backup automático (5.2)
sigue funcionando** y sobrevive reinicios porque vive fuera del bundle (6.4).

## 3. Impresora

- **Red (recomendado):** en Configuración → Impresión, transporte "red",
  dirección `IP` o `IP:9100`. Funciona igual que en Windows, sin cambios.
- **USB/local:** transporte "usb" y en dirección poné:
  - el nombre de una **cola CUPS** (se imprime con `lp -o raw`), o
  - una ruta de dispositivo tipo `/dev/usb/lp0` (escritura RAW directa; el
    usuario debe estar en el grupo `lp`: `sudo usermod -aG lp $USER`).

## 4. Arranque automático

Elegí **una** opción:

**a) systemd de usuario (preferido — reinicia tras crashes):**
```bash
mkdir -p ~/.config/systemd/user
cp latercia-kiosk.service ~/.config/systemd/user/
# editar ExecStart si la ruta difiere
systemctl --user daemon-reload
systemctl --user enable --now latercia-kiosk.service
loginctl enable-linger $USER   # que corra sin login interactivo
```

**b) autostart del escritorio:**
```bash
mkdir -p ~/.config/autostart
cp latercia-kiosk.desktop ~/.config/autostart/
```

Además, activá **autologin** del usuario del kiosko en el gestor de sesión
(GDM/LightDM) para que la sesión gráfica arranque sola al encender.

## 5. Pantalla completa y bloqueo de salida

Se controla **desde la propia app**: Configuración → Kiosko → "Modo kiosko" ON.
Eso pone pantalla completa y **bloquea el cierre** de la ventana (mecanismo en
`KioskController`). Para salir: apagá el flag en Configuración y la ventana se
libera al instante (escape seguro, sin tener que matar el proceso).

## 5b. Modo "electrodoméstico": arrancar SOLO la app al encender

Para que la PC encienda y lo **único** que aparezca sea La Tercia (sin
escritorio, sin barras, sin forma de salir al SO) — como si el POS fuera el
sistema operativo — usá **`cage`** (compositor de una sola app) + **autologin**.
Lubuntu 24.04 usa **SDDM** como gestor de login.

**1) Instalá cage:**
```bash
sudo apt install -y cage
```

**2) Creá una "sesión" que arranque la app en cage.** Como root, creá el archivo
`/usr/share/wayland-sessions/latercia-kiosk.desktop` con:
```ini
[Desktop Entry]
Name=La Tercia Kiosko
Comment=POS en modo electrodoméstico
Exec=cage -- /opt/latercia/latercia
Type=Application
```
(Ajustá la ruta del binario. Para probar sin instalar en /opt, apuntá al bundle:
`/home/jaimel/LaTercia/build/linux/x64/release/bundle/latercia`.)

**3) Autologin a esa sesión.** Creá `/etc/sddm.conf.d/autologin.conf`:
```ini
[Autologin]
User=jaimel
Session=latercia-kiosk
```

**4) Reiniciá.** La PC arranca → SDDM autologin → `cage` lanza la app a pantalla
completa. No hay escritorio ni forma de cerrarla. La bienvenida ("Bienvenido…")
la muestra la propia app.

**Salir/apagar en este modo:** ya no hay menú del SO, así que:
- **Apagar/Reiniciar** desde **Configuración → Equipo** (botones en la app).
- Para **mantenimiento** (volver al escritorio normal), desde otra TTY:
  `Ctrl+Alt+F3` → login → `sudo rm /etc/sddm.conf.d/autologin.conf` → reiniciar.

> Con cage no hace falta el flag "Modo kiosko" de la app (cage ya la deja a
> pantalla completa y sin cierre). El flag interno sigue siendo útil para el
> modo más simple (autostart sobre el escritorio) de la sección 4/5.

## 6. Checklist de verificación en la VM (6.3)

- [ ] `flutter build linux --release` compila sin errores.
- [ ] La app arranca; login con PIN funciona.
- [ ] Flujo completo: venta → cocina → cobro → corte Z.
- [ ] Rutas de datos/logs/backups en `~/.local/share/latercia/`.
- [ ] Backup automático corre (revisar `backups/`) y sobrevive reinicio.
- [ ] Impresión de red (si hay impresora) o ticket de prueba.
- [ ] Modo kiosko ON: pantalla completa + no se puede cerrar; OFF lo libera.
- [ ] Arranca solo tras reiniciar la VM (systemd/autostart + autologin).
- [ ] Si la app crashea, systemd la reinicia (probá `killall latercia`).
- [ ] Botones **Configuración → Equipo → Apagar/Reiniciar** funcionan.
- [ ] Modo electrodoméstico (§5b): al reiniciar arranca directo en la app con
      cage, sin escritorio ni forma de salir.
