# La Tercia POS — kiosko Linux (Fase 6)

Guía para montar la app como kiosko que arranca sola al encender la PC. Probar
primero en una **máquina virtual Linux** (6.3) antes de la estación del cliente.

Recomendado: distro con Wayland y GNOME, o un compositor de una-sola-app como
`cage` (lo más "kiosko" posible).

---

## 1. Compilar

Requisitos de build de Flutter Linux (una vez):
```bash
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev \
  liblzma-dev libstdc++-12-dev
flutter config --enable-linux-desktop
```

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

Para un kiosko "duro" (sin escritorio ni forma de salir del compositor),
arrancá la app dentro de `cage`:
```bash
sudo apt install -y cage
# como sesión: cage /opt/latercia/latercia
```
`cage` muestra una sola app a pantalla completa sin barras ni acceso al SO.

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
