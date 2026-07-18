# Instructivo de despliegue — La Tercia POS (estación del cliente)

Guía para instalar el POS en la PC del cliente como **kiosko que arranca solo**.
Pensado para seguir paso a paso en sitio. Tiempo estimado: 30–60 min.

> **Regla de oro:** compila el `bundle` **antes** de ir (en tu máquina o la VM) y
> llévalo en USB. En la PC del cliente NO se instala Flutter ni herramientas de
> compilación — solo librerías de ejecución. Es más rápido y limpio.

---

## 0. Antes de ir (en tu máquina / VM)

- [ ] Compilar el bundle de producción:
  ```bash
  flutter build linux --release
  ```
- [ ] Copiar a un USB **toda** la carpeta:
  `build/linux/x64/release/bundle/`  → (queda el binario `latercia` + `lib/` + `data/`).
- [ ] Llevar también este repo (o al menos la carpeta `linux_kiosk/`) en el USB.
- [ ] Tener a la mano los datos del cliente: nombre del negocio, logo, IVA,
  empleados + PINs, catálogo de productos, y datos de la **impresora**
  (IP de red, o nombre de cola CUPS / puerto USB).

**Requisitos de la PC del cliente:** Ubuntu/Lubuntu 24.04 (u otra con escritorio),
con GPU real (así el arranque tipo electrodoméstico con `cage` va sin parpadeo).
Recomendado un usuario dedicado (aquí asumimos `pos`; ajusta las rutas).

---

## 1. Dependencias de ejecución (en la PC del cliente)

El bundle usa librerías del sistema. En un escritorio completo casi todas están;
instala las de audio, impresión y el compositor kiosko:

```bash
sudo apt update
sudo apt install -y gstreamer1.0-plugins-base gstreamer1.0-plugins-good cups cage
```

*(Si al ejecutar la app se queja de `libgtk-3` u otra librería, instala su paquete
runtime: `sudo apt install -y libgtk-3-0`.)*

---

## 2. Instalar la app

Con el USB montado (ajusta la ruta real del USB):

```bash
sudo mkdir -p /opt/latercia
sudo cp -r /media/pos/USB/bundle/* /opt/latercia/
sudo chmod +x /opt/latercia/latercia
```

Prueba que arranca (desde el escritorio gráfico):
```bash
/opt/latercia/latercia
```
Debe abrir la pantalla de PIN. Si abre, vas bien. Ciérrala para seguir.

---

## 3. Primer arranque y configuración (dentro de la app)

**Credenciales por defecto (¡cámbialas!):**
- Admin — PIN **`0000`**
- Cajero — PIN **`1234`**

1. Entra con **PIN `0000`** (admin) → **Administración**.
2. **Configuración → Negocio:** nombre, slogan, logo del cliente.
3. **Configuración → Impuestos:** IVA % y si el precio ya incluye IVA (default: incluido).
4. **Configuración → Moneda / Ticket:** símbolo, decimales, pie de ticket.
5. **Admin → Empleados:**
   - [ ] **Cambia el PIN del Administrador** (no dejar `0000`).
   - [ ] Crea los cajeros reales con sus PINs y borra/renombra el "Cajero" demo.
6. **Admin → Productos / Categorías:** carga el catálogo del cliente (o revísalo).

> ⚠️ **Seguridad:** los PINs `0000`/`1234` son públicos (están en este manual).
> Cambiarlos en sitio es obligatorio.

---

## 4. Impresora

**Opción A — Red (recomendada):**
1. Conecta la impresora a la red; anota su IP.
2. **Configuración → Impresión:** activa impresión, transporte **"red"**,
   dirección `IP` o `IP:9100`, ancho 58/80 mm.
3. Botón **"Imprimir ticket de prueba"**.

**Opción B — USB (vía CUPS):**
1. Da de alta la impresora en CUPS (interfaz web `http://localhost:631` o
   `system-config-printer`), como cola **raw**.
2. Agrega el usuario al grupo de impresión: `sudo usermod -aG lp pos` (reinicia sesión).
3. **Configuración → Impresión:** transporte **"usb"**, dirección = **nombre de la
   cola CUPS** (o una ruta `/dev/usb/lp0` para escritura directa).
4. Ticket de prueba.

**Gaveta de dinero** (si hay): **Configuración → Impresión y gaveta** → activa
gaveta; abre por pulso a través de la impresora térmica.

---

## 5. Modo electrodoméstico: arranca solo en la app al encender

En hardware real con GPU, usamos **`cage`** (compositor de una sola app) + autologin.
La PC enciende y lo único que aparece es el POS, sin escritorio ni forma de salir.

**5.1** Crear la sesión kiosko (como root):
```bash
sudo tee /usr/share/wayland-sessions/latercia-kiosk.desktop > /dev/null <<'EOF'
[Desktop Entry]
Name=La Tercia Kiosko
Comment=POS
Exec=cage -- /opt/latercia/latercia
Type=Application
EOF
```

**5.2** Autologin (Lubuntu 24.04 usa **SDDM**). Confirma el gestor con
`cat /etc/X11/default-display-manager` (debe decir `.../sddm`). Luego:
```bash
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null <<'EOF'
[Autologin]
User=pos
Session=latercia-kiosk
EOF
```

**5.3** Prueba `cage` **antes** de reiniciar (para no quedar en pantalla negra).
En una TTY (`Ctrl+Alt+F3` → login):
```bash
cage -- /opt/latercia/latercia
```
Si abre la app a pantalla completa → todo bien (`Ctrl+Alt+F1` para volver). Si da
error de renderer, la GPU no está habilitada — revisa drivers; como plan B usa el
método autostart de `setup.md` §4–5.

**5.4** Reinicia: `sudo reboot`. Debe arrancar directo en el POS.

> Con `cage` no hace falta el flag interno "Modo kiosko" (cage ya deja la app
> fullscreen y sin cierre). Puedes dejarlo OFF.

---

## 6. Respaldos

- **Configuración → Respaldo:** deja **Backup automático ON** (diario + al cerrar
  turno) y define la retención (14 días por defecto).
- Los respaldos viven en `/home/pos/.local/share/latercia/backups/`.
- **Recomendado:** cada cierto tiempo copia esa carpeta a un USB externo
  (los backups locales no protegen contra falla del disco).

---

## 7. Apagar / reiniciar el equipo

Como en kiosko no hay menú del sistema, se hace **desde la app**:
**Configuración → Equipo → Apagar / Reiniciar** (con confirmación).

---

## 8. Mantenimiento y emergencias

- **Salir del kiosko para mantenimiento:** `Ctrl+Alt+F3` → login →
  `sudo rm /etc/sddm.conf.d/autologin.conf` → `sudo reboot` (arranca al escritorio
  normal). Para re-activar, vuelve a crear ese archivo.
- **Logs de la app:** `/home/pos/.local/share/latercia/logs/` (uno por día).
- **Base de datos:** `/home/pos/.local/share/latercia/latercia.db`.
- **Actualizar la app:** recompila el bundle, cópialo sobre `/opt/latercia/`,
  reinicia. Los datos NO se tocan (viven en `~/.local/share/latercia/`).
- **Restaurar un backup:** Configuración → Respaldo → Restaurar (se aplica al
  reiniciar).

---

## 9. Checklist final de entrega

- [ ] La app arranca sola al encender la PC (kiosko).
- [ ] PINs por defecto cambiados; cajeros reales creados.
- [ ] Negocio/IVA/moneda/ticket configurados.
- [ ] Catálogo cargado y con precios correctos.
- [ ] Impresora imprime ticket de prueba y comanda de cocina.
- [ ] (Si aplica) gaveta abre al cobrar en efectivo.
- [ ] Flujo completo probado: turno → venta → cocina → cobro → **corte Z**.
- [ ] Backup automático ON; hecha una copia externa inicial a USB.
- [ ] Botones Apagar/Reiniciar funcionan.
- [ ] El cliente sabe: su PIN de admin, cómo abrir/cerrar turno y hacer el corte Z.

---

*Pendiente futuro: botonera de cocina (Arduino Uno por USB-serial) — se instala
cuando esté el hardware; no bloquea la operación del POS.*
