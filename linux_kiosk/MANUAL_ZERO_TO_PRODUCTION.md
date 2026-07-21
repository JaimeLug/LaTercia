# Manual de Instalación Zero-to-Production — La Tercia POS
**Estación física del cliente · Lubuntu/Ubuntu 24.04 · modo electrodoméstico**

Manual completo, pensado para ejecutarse **sin experiencia previa en Linux**.
Cada comando viene exacto (cópialo tal cual), con lo que deberías ver al
correrlo y qué hacer si sale otra cosa. Tiempo estimado en sitio: 2–4 h.

**Mapa del proceso:**

```
FASE 0 (en tu casa, VM Linux)  →  compilar el bundle, pasarlo a USB y
                                  pre-validar la botonera ESP32 contra la VM
FASE 1 (PC del cliente)        →  instalar Lubuntu desde USB booteable
FASE 2                         →  actualizar sistema + dependencias
FASE 3                         →  copiar la app a /opt/latercia y probarla
FASE 4                         →  autologin + modo kiosko
FASE 5                         →  impresora, botonera ESP32, checklist final
FASE 6                         →  actualizaciones futuras (y la transición
                                  única a la versión con módulo de updates)
```

**Convenciones de este manual:**
- `$` al inicio de una línea = comando que tecleas en la terminal (no
  escribas el `$`). Todo lo demás es salida esperada o comentario.
- Cuando un comando empieza con `sudo`, te pedirá **tu contraseña** (la del
  usuario con que iniciaste sesión). Al teclearla **no se ven asteriscos ni
  nada** — es normal, teclea y da Enter.
- "Abrir una terminal": en Lubuntu, menú de inicio → Herramientas del sistema
  → QTerminal (o atajo `Ctrl+Alt+T` en Ubuntu).

---

# FASE 0 — Compilar el bundle (ANTES de ir, en tu VM Linux)

⚠️ **El bundle NO se puede compilar en Windows.** `flutter build linux` solo
corre en Linux. Se compila en tu **VM Linux** (la misma donde ya probaste el
kiosko, usuario `jaimel`).

### 0.1 Actualizar el código en la VM

Enciende la VM y abre una terminal. El repo vive en `/home/jaimel/LaTercia`.
Trae la última versión del código (según cómo lo pases normalmente):

**Opción A — con git (si el repo de la VM está conectado al remoto):**
```bash
cd ~/LaTercia
git pull
```

**Opción B — copiando la carpeta desde Windows** (carpeta compartida de la VM
o un USB): reemplaza el contenido de `~/LaTercia` con la versión nueva.
Después de copiar, dentro de la VM:
```bash
cd ~/LaTercia
```

### 0.2 Dependencias de compilación (solo la primera vez)

Si esta VM ya compiló la app antes, sáltate este paso. Si es una VM nueva:
```bash
cd ~/LaTercia
bash linux_kiosk/install-deps.sh
```
Ese script corre `apt update`, instala toolchain (clang, cmake, ninja, GTK),
GStreamer y CUPS dev, y habilita el escritorio Linux en Flutter. Tarda varios
minutos. Si algún paquete falla, revisa que la VM tenga internet
(`ping -c 3 google.com`).

### 0.3 Compilar

```bash
cd ~/LaTercia
flutter clean
flutter pub get
flutter build linux --release
```

- `flutter clean` borra compilaciones viejas — evita que un build a medias
  contamine el release.
- El build tarda 5–15 min la primera vez. Termina sin mensaje de error y te
  regresa al prompt.

**Verifica que el bundle quedó completo:**
```bash
ls build/linux/x64/release/bundle/
```
Debes ver exactamente tres cosas:
```
data  latercia  lib
```
- `latercia` = el binario ejecutable.
- `lib/` = librerías (Flutter engine + plugins).
- `data/` = assets (íconos, sonidos, fuentes).

**Prueba rápida antes de copiar** (que abra la pantalla de PIN):
```bash
./build/linux/x64/release/bundle/latercia
```
Si abre, ciérrala. Si no abre, NO sigas — arregla el build primero (el error
sale en esa misma terminal).

**Ramificación — "flutter: command not found":** Flutter no está en el PATH de
esa terminal. Si instalaste Flutter en `~/flutter`, corre:
```bash
export PATH="$PATH:$HOME/flutter/bin"
flutter --version
```
y repite 0.3. Para hacerlo permanente:
`echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc`

**Ramificación — "No Linux desktop project configured":** falta la carpeta
`linux/` (no debería, ya está commiteada, pero si copiaste el proyecto a mano
y se perdió):
```bash
flutter create --platforms=linux .
flutter build linux --release
```

### 0.4 Pasar el bundle al USB

Necesitas **2 memorias USB**:
- **USB-1 "instalador"**: donde grabarás la ISO de Lubuntu (Fase 1.1). Se
  borra por completo al grabarla — no pongas nada más ahí.
- **USB-2 "despliegue"**: el bundle + la carpeta `linux_kiosk/` del repo.
  Formato normal (FAT32/exFAT/NTFS, cualquiera sirve).

**Para copiar al USB-2 desde la VM**, conecta el USB a la máquina física y
pásalo a la VM:
- **VirtualBox:** menú `Dispositivos → USB → (tu memoria)`. Aparecerá montada
  en el explorador de archivos de la VM (típicamente en `/media/jaimel/...`).
- **VMware:** menú `VM → Removable Devices → (tu memoria) → Connect`.
- **Si el passthrough USB no funciona** (pasa seguido en VirtualBox sin el
  Extension Pack): copia el bundle a la **carpeta compartida** de la VM, y
  desde Windows cópialo del folder compartido al USB. Mismo resultado.

Ya con el USB visible en la VM:
```bash
# Averigua cómo se montó el USB:
ls /media/jaimel/
# (verás el nombre de tu memoria, p.ej. "KINGSTON" — úsalo abajo)

cp -r ~/LaTercia/build/linux/x64/release/bundle /media/jaimel/KINGSTON/
cp -r ~/LaTercia/linux_kiosk /media/jaimel/KINGSTON/
sync    # ← IMPORTANTE: fuerza la escritura real al USB antes de sacarlo
```
`sync` puede tardar un poco sin mostrar nada — espera a que regrese el prompt
y luego expulsa el USB desde el explorador de archivos (o
`umount /media/jaimel/KINGSTON`).

**⚠️ La base de datos NO viaja con el bundle.** El bundle solo lleva el
programa; el catálogo, empleados, configuración, etc. viven en un archivo
aparte que hay que llevar explícitamente. La base "buena" (la del catálogo
real ya cargado) está en **Windows**, en:
```
C:\Users\jaime\Documents\latercia.sqlite
```
Con la app de Windows **cerrada** (POS y KDS), copia ese archivo al USB-2.
*(Alternativa más ordenada: en la app de Windows, Configuración → Respaldo →
exportar un respaldo fresco, y copiar ese archivo al USB-2 — se restaura en
sitio con Configuración → Respaldo → Restaurar.)*

**Verificación final del USB-2** (en cualquier máquina): debe contener
`bundle/` (con `latercia`, `lib/`, `data/` adentro), `linux_kiosk/` y
`latercia.sqlite` (o el archivo de respaldo exportado).

---

### 0.5 Pre-validar la botonera ESP32 contra la VM (PENDIENTE — hazlo antes de ir)

⚠️ **La botonera todavía no se ha probado en Linux** (solo en Windows). Es lo
único de hardware que SÍ puedes validar desde casa, y conviene hacerlo antes
de ir a sitio: si algo falla ahí, lo depuras con calma en tu escritorio y no
frente al cliente.

*(La impresora y la gaveta NO se pueden pre-validar — ese hardware está en el
local. Su primera prueba real será en sitio, Fases 5.3–5.4; por eso esas
secciones traen la verificación por terminal ANTES de tocar la app.)*

**Trampa de red de la VM (léelo antes de probar):** con la configuración de
red por defecto de VirtualBox/VMware (**NAT**), la VM puede salir a internet
pero **nadie de la red local puede entrarle** — el ESP32 jamás la alcanzará,
aunque el servidor esté corriendo bien. Hay que poner la VM en modo
**puente (bridged)** para que tenga su propia IP en la red de tu casa:

1. Apaga la VM.
2. **VirtualBox:** Configuración → Red → Adaptador 1 → "Conectado a:"
   **Adaptador puente** → elige tu tarjeta de red real (la Wi-Fi si tu PC va
   por Wi-Fi). **VMware:** VM → Settings → Network Adapter → **Bridged**.
3. Enciende la VM y confirma que ahora tiene IP de tu red casera:
   ```bash
   ip addr show | grep "inet " | grep -v 127.0.0.1
   # → debe ser del rango de tu casa (p.ej. 192.168.1.x),
   #   NO 10.0.2.x (esa es la IP interna de NAT — sigue en NAT, revisa el paso 2)
   ```

**La prueba en sí:**
1. En la VM, abre la app y entra a la **pantalla del KDS** (el servidor de la
   botonera solo arranca con esa pantalla abierta).
2. Confirma que escucha:
   ```bash
   ss -tlnp | grep 8080
   # → LISTEN ... 0.0.0.0:8080 ... latercia
   ```
3. Apunta el firmware del ESP32 a la **IP de la VM** (la del paso 3 de
   arriba) y enciéndelo. Deja que se conecte al Wi-Fi de tu casa.
4. Pulsa cada botón de la botonera → en el KDS de la VM debe sonar la
   alerta / verse el evento, botón por botón.
5. Prueba de robustez: cierra la pantalla del KDS y vuélvela a abrir, y
   reinicia el ESP32 → la botonera debe reconectarse sola y seguir
   funcionando.

**Si no conecta:** repasa la ramificación de la Fase 5.5 (mismo diagnóstico:
`ss -tlnp`, IP correcta, y el "AP isolation" del router — algunos routers
domésticos lo traen activo en la banda de invitados).

> Nota para el día de la instalación: en sitio la IP de la PC será **otra**
> (la de la red del local, Fase 5.5) — si el firmware lleva la IP fija de tu
> casa, tendrás que actualizarla en sitio. Ten a la mano lo necesario para
> reconfigurar el ESP32 (cable y laptop con el entorno de flasheo, o el
> mecanismo de configuración que tenga tu firmware).

---

# FASE 1 — Instalar Lubuntu en la PC del cliente

**Contexto del hardware:** PC de ~2010–2014. Eso implica:
- Puede ser **BIOS Legacy** (sin UEFI) o UEFI de primera generación — la
  Fase 1.1 cubre ambos.
- GPU integrada vieja (Intel HD de esa época): si usas el método de un solo
  monitor (`cage`, Fase 4.3-alt), es probable que necesite el modo por
  software (`LIBGL_ALWAYS_SOFTWARE=1`) — no te asustes si pasa, ya está
  previsto y es el mismo modo que corre en tu VM.
- RAM posiblemente 2–4 GB → por eso **Lubuntu** (escritorio LXQt ligero) en
  vez de Ubuntu normal. La app corre bien; solo evita abrir mil cosas a la
  vez durante la instalación.

### 1.1 Grabar el USB booteable (en tu PC Windows, con la ISO que ya tienes)

1. Descarga **Rufus** de `rufus.ie` (versión portable, no requiere
   instalación) y ábrelo.
2. **Dispositivo:** selecciona el USB-1. ⚠️ Se borra todo lo que tenga.
3. **Elección de arranque:** botón "SELECCIONAR" → tu ISO de Lubuntu 24.04.
4. **Esquema de partición** — aquí está la ramificación clave para una PC
   vieja:
   - Elige **MBR** + sistema de destino **"BIOS o UEFI"**. Es la opción más
     compatible: arranca tanto en BIOS Legacy (probable en 2010–2012) como en
     UEFI (posible en 2013–2014).
   - Solo usarías GPT si ya supieras con certeza que la PC es UEFI puro — con
     MBR no pierdes nada en este hardware.
5. Clic en **"EMPEZAR"**. Si Rufus pregunta el modo de escritura, elige
   **"Escribir en modo Imagen DD"** — evita el fallo más común de "la PC no
   ve el USB".
6. Espera a que la barra diga "PREPARADO" (~5–10 min) y expulsa el USB.

### 1.2 Arrancar la PC del cliente desde el USB

1. Conecta el USB-1 (usa un **puerto USB trasero** — en PCs viejas los
   frontales a veces fallan al arrancar) y enciende la PC.
2. En cuanto aparezca el logo del fabricante, presiona repetidamente la tecla
   del **menú de arranque**:

   | Fabricante | Menú de arranque | Entrar al BIOS |
   |---|---|---|
   | Dell | F12 | F2 |
   | HP | F9 (o Esc y luego F9) | F10 |
   | Lenovo | F12 | F1 o F2 |
   | Acer | F12 (a veces hay que habilitarlo en BIOS) | F2 o Del |
   | Asus / clones / armadas | F8 o Esc | Del |

3. En el menú, elige tu memoria USB (puede aparecer por marca: "Kingston
   DataTraveler", "USB HDD", etc.) y da Enter.
4. Debe aparecer el menú de Lubuntu → elige **"Try or Install Lubuntu"**.

**Ramificación — el USB no aparece en el menú de arranque:**
1. Prueba **otro puerto USB** (trasero, y si hay puertos negros y azules,
   prueba el negro = USB 2.0; algunos BIOS viejos no arrancan de USB 3.0).
2. Entra al BIOS (tecla de la tabla) y busca:
   - **"Fast Boot"** → ponlo en **Disabled** (salta la detección de USB).
   - **"Boot Mode"** o "OS Type": si dice "UEFI only", cámbialo a
     **"Legacy"**, **"CSM"** o **"UEFI + Legacy"**.
   - **Orden de arranque (Boot Order/Priority):** sube "USB HDD" o
     "Removable Devices" arriba del disco duro.
   - Guarda con **F10** → Yes → la PC reinicia.
3. Si sigue sin verse: regrabá el USB en Rufus pero cambiando el esquema (si
   usaste MBR prueba GPT, o viceversa) y modo DD.
4. Último recurso en PCs muy viejas: graba la ISO a un **DVD** si la PC tiene
   lector, o prueba con otra memoria USB (las >64 GB a veces dan problemas
   en BIOS antiguos — ideal una de 8–16 GB).

**Mientras estés dentro del BIOS — dos ajustes de "electrodoméstico"
(hazlos ahora, que ya estás ahí; o vuelve al BIOS al final):**

1. **Encendido automático tras corte de luz:** busca una opción llamada
   **"Restore on AC Power Loss"**, "AC Back", "After Power Failure" o
   similar (suele estar en Power Management / Advanced) y ponla en
   **"Power On"**. Con esto, cuando se vaya la luz en el local y regrese, la
   PC **enciende sola** y el POS vuelve a estar operativo sin que nadie tenga
   que agacharse a buscar el botón. Es EL ajuste de electrodoméstico por
   excelencia.
2. **Revisa la fecha/hora del BIOS.** Si está muy desfasada (año 2010, o se
   resetea cada vez que desconectas la PC de la corriente), la **pila CMOS
   está muerta** — normalísimo en una PC de esta edad. Es una pila de botón
   **CR2032** (~$20–30 pesos): cámbiala antes de entregar. Con la pila muerta
   y sin internet, el reloj arrancaría mal cada día → tickets, turnos y
   cortes Z con fecha/hora incorrecta.

**Ramificación — Secure Boot da error de firma (solo en UEFI 2013–2014):**
Entra al BIOS → pestaña Security o Boot → **Secure Boot → Disabled** → F10
para guardar. En un POS dedicado no hay razón para reactivarlo.

**Ramificación — arranca pero se congela en pantalla negra o logo:** en el
menú inicial de arranque del USB, presiona `E` sobre la opción de instalar,
busca la línea que termina en `quiet splash` y agrega ` nomodeset` al final,
luego `F10` o `Ctrl+X` para arrancar. (`nomodeset` desactiva el driver
gráfico durante la instalación — típico salvavidas en GPUs viejas.)

### 1.3 Instalación guiada (pantalla por pantalla)

1. **Idioma:** Español → "Instalar Lubuntu".
2. **Teclado:** el que corresponda (para México: "Spanish (Latin American)" —
   pruébalo en la cajita de texto: teclea `ñ` y `@` para confirmar).
3. **Red:** si hay cable de red, conéctalo (lo más simple). Si es Wi-Fi,
   conéctate ahora a la red del local (elige el SSID, mete la contraseña).
   *Si el Wi-Fi no aparece, no te detengas: instala sin red y resuélvelo en
   la Fase 2 (ramificación de Wi-Fi).*
4. **Tipo de instalación:** "Borrar disco" / **"Erase disk and install"**.
   ⚠️ **Punto de no retorno:** borra TODO el disco. Confirma antes con el
   cliente que no hay nada que rescatar en esa PC.
   - Particionado: deja el automático (una partición `/` ext4 + swap). Para
     un kiosko de un solo uso no se necesita nada manual.
   - Si aparece opción de formato, deja **ext4** (default).
5. **Usuario:**
   - Nombre: `pos`
   - Nombre del equipo: `latercia-caja1`
   - Contraseña: una que **tú y el dueño recuerden** (se usa para `sudo` y
     para el mantenimiento por TTY; con el autologin de la Fase 4 no se pide
     en el día a día). Anótala en la hoja de entrega.
   - Marca **"Iniciar sesión automáticamente"** si el instalador lo ofrece
     (de todas formas el autologin real del kiosko se configura en Fase 4).
6. Revisa el resumen → **"Instalar"**. Tarda 10–30 min según la PC.
7. Al terminar: "Reiniciar ahora" → **retira el USB-1 cuando lo pida** →
   Enter.
8. Debe arrancar al escritorio de Lubuntu con el usuario `pos`.

---

# FASE 2 — Actualizar el sistema e instalar dependencias

Abre una terminal (menú → Herramientas del sistema → QTerminal).

### 2.1 Verificar internet primero

```bash
ping -c 3 google.com
```
Debes ver 3 líneas con tiempos (`64 bytes from ... time=20 ms`). Si dice
`Name or service not known` o `Network is unreachable`, no hay red — resuelve
la ramificación de abajo antes de seguir (todo lo demás depende de internet).

**Ramificación — conectar el Wi-Fi:**
- **Por interfaz gráfica (lo más fácil):** clic en el ícono de red en la
  esquina inferior derecha de la barra → elige la red del local → contraseña.
- **Por terminal:**
  ```bash
  nmcli device wifi list
  # (lista las redes visibles; identifica el SSID del local)
  nmcli device wifi connect "NOMBRE_DE_LA_RED" password "CONTRASEÑA"
  # Salida esperada: "Device 'wlxxx' successfully activated..."
  ```
- **Ramificación de la ramificación — no aparece ninguna red / no hay
  adaptador Wi-Fi:** en PCs de escritorio viejas es común que NO tengan
  Wi-Fi integrado. Verifica:
  ```bash
  nmcli device status
  ```
  Si no hay ninguna línea tipo `wifi`, la PC no tiene tarjeta Wi-Fi. Opciones:
  1. **Cable de red al router** (la mejor para un POS: más estable). El POS
     y el ESP32 solo necesitan estar en la **misma red**, no ambos en Wi-Fi.
  2. Un **adaptador USB Wi-Fi** — pero ojo, muchos necesitan driver; si vas a
     comprar uno, busca chipset Atheros o Realtek RTL8188EU (soportados de
     fábrica en Ubuntu 24.04).
  Si hay línea `wifi` pero dice `unavailable`, el driver falta; con cable de
  red conectado corre `sudo ubuntu-drivers autoinstall` y reinicia.

### 2.2 Actualizar el sistema

```bash
sudo apt update
```
- Pide tu contraseña (no se ve al teclear — normal). Debe terminar sin
  errores, tipo `Reading package lists... Done`.
- **Ramificación — errores de "Failed to fetch":** casi siempre es internet
  intermitente; verifica el ping y reintenta.

```bash
sudo apt upgrade -y
```
Tarda 10–40 min en una instalación fresca con PC vieja. Al terminar:
```bash
sudo reboot
```
(Reiniciar aquí es obligatorio si actualizó el kernel; hacerlo siempre no
cuesta nada y evita rarezas.)

### 2.3 Instalar dependencias de ejecución

Tras el reinicio, terminal de nuevo. Instala todo de una vez — aunque en la
Fase 4 solo termines usando uno de los dos métodos de kiosko (`cage` o
`wmctrl`), es más simple dejar ambos listos ahora que decidir a medias:
```bash
sudo apt install -y gstreamer1.0-plugins-base gstreamer1.0-plugins-good cups cage wmctrl xdotool
```
Qué es cada cosa:
- `gstreamer...`: sonidos de alerta del KDS.
- `cups`: sistema de impresión (para impresora USB; no estorba si es de red).
- `cage`: compositor para el método de kiosko de **un solo monitor** (Fase 4.3-alt).
- `wmctrl`/`xdotool`: acomodo de ventanas para el método de **dos monitores** (Fase 4.3).

Verifica que quedaron:
```bash
which cage wmctrl xdotool
# → /usr/bin/cage, /usr/bin/wmctrl, /usr/bin/xdotool
systemctl status cups --no-pager | head -3
# → debe decir "active (running)"
```

### 2.4 Ajustes de "electrodoméstico" del sistema

**a) Zona horaria y reloj.** Un POS vive de la hora correcta (turnos, cortes
Z, backups con fecha). Verifica:
```bash
timedatectl
```
Revisa tres líneas de la salida:
- `Time zone:` debe ser la del negocio (p.ej. `America/Mexico_City`). Si no:
  ```bash
  timedatectl list-timezones | grep America/Mex   # busca la correcta
  sudo timedatectl set-timezone America/Mexico_City
  ```
- `System clock synchronized: yes` — la hora se ajusta sola por internet
  (NTP). Si dice `no`:
  ```bash
  sudo timedatectl set-ntp true
  ```
- `Local time:` debe coincidir con tu reloj. Si el local NO va a tener
  internet permanente, el reloj depende de la pila CMOS (ver el ajuste de
  BIOS en la Fase 1.2) — con pila nueva aguanta años; sin pila, la hora se
  pierde en cada corte de luz.

**b) Prohibir que la PC se suspenda.** Un kiosko jamás debe dormirse:
```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
# → 4 líneas "Created symlink ... → /dev/null"
```
Con eso, ni una actualización ni una tecla rara pueden mandar la PC a
suspensión (de la que nadie en la cafetería sabría despertarla).

**Ramificación — "Unable to locate package cage":** te faltó `apt update`
(2.2) o falta el repositorio "universe":
```bash
sudo add-apt-repository universe -y
sudo apt update
sudo apt install -y cage
```

---

# FASE 3 — Copiar y probar la aplicación

### 3.1 Montar el USB-2 (el del bundle)

Conecta el USB-2. En Lubuntu normalmente **se monta solo** y sale una
notificación / aparece en el explorador de archivos (PCManFM). Su ruta será
`/media/pos/NOMBRE_DEL_USB/`.

```bash
ls /media/pos/
# → verás el nombre de tu memoria, p.ej.: KINGSTON
ls /media/pos/KINGSTON/
# → debe listar: bundle  linux_kiosk
```

**Ramificación — no se montó solo:**
```bash
lsblk
```
Busca el dispositivo del USB: es el que coincide con el tamaño de tu memoria
y NO tiene particiones montadas en `/` (típicamente `sdb1` si el disco
interno es `sda`). Móntalo a mano:
```bash
sudo mkdir -p /mnt/usb
sudo mount /dev/sdb1 /mnt/usb
ls /mnt/usb
# → bundle  linux_kiosk
```
(y en los comandos siguientes usa `/mnt/usb/` en lugar de
`/media/pos/KINGSTON/`).

### 3.2 Copiar la app a su ruta definitiva

```bash
sudo mkdir -p /opt/latercia
sudo cp -r /media/pos/KINGSTON/bundle/* /opt/latercia/
sudo chmod +x /opt/latercia/latercia
```

Verifica:
```bash
ls /opt/latercia/
# → data  latercia  lib
/opt/latercia/latercia --version 2>/dev/null; ls -l /opt/latercia/latercia
# → la línea de ls debe empezar con -rwxr-xr-x (las "x" = permisos de ejecución)
```

Copia también la carpeta `linux_kiosk` a la home (la usarás en la Fase 4 como
referencia y por si necesitas el servicio systemd):
```bash
cp -r /media/pos/KINGSTON/linux_kiosk ~/
```

### 3.3 Primera ejecución de prueba

Desde el escritorio (todavía sin kiosko):
```bash
/opt/latercia/latercia
```
**Debe abrir la pantalla de PIN.** Entra con PIN `0000` (admin) para
confirmar que todo carga, y ciérrala.

**Ramificación — "error while loading shared libraries: libXXX.so: cannot
open shared object file":** falta una librería del sistema. El nombre entre
`lib` y `.so` te dice cuál. Las más probables:
```bash
# libgtk-3.so.0 →
sudo apt install -y libgtk-3-0t64
# (en 24.04 el paquete se llama con sufijo t64; si no existe, prueba libgtk-3-0)
# libsqlite3.so →
sudo apt install -y libsqlite3-0
```
Para cualquier otra, búscala así:
```bash
apt-cache search NOMBRE_DE_LA_LIB | head -5
```
e instala el paquete runtime (el que NO termina en `-dev`).

**Ramificación — abre pero se ve en blanco o crashea al instante:** corre
desde terminal y lee el error. Si menciona GL/GPU/renderer, prueba:
```bash
LIBGL_ALWAYS_SOFTWARE=1 /opt/latercia/latercia
```
Si así sí abre, la GPU de esta PC no puede con el render acelerado —
**apúntalo**: en la Fase 4 irás directo a la variante "software rendering"
(4.3-alt si es un monitor, o con `LIBGL_ALWAYS_SOFTWARE=1` agregado al script
de 4.3 si son dos).

### 3.3b Cargar la base de datos con el catálogo real

La primera ejecución (3.3) creó una base **vacía** (con los defaults de
fábrica). Ahora reemplázala por la base buena que traes en el USB-2.

**Opción A — reemplazo directo del archivo:**
1. Cierra la app por completo.
2. Localiza dónde creó la app su base en esta PC:
   ```bash
   find ~ -name "latercia.sqlite*" 2>/dev/null
   # → lo esperado: /home/pos/.local/share/mx.latercia.pos/latercia.sqlite
   #   (pueden aparecer también latercia.sqlite-wal / -shm)
   ```
   *(La base vive en la carpeta de soporte de la app, no en Documentos — el
   nombre `mx.latercia.pos` sale del bundle ID; si algún día cambia, este
   `find` lo sigue encontrando igual.)*
3. Reemplaza (ajusta las rutas a lo que te dio el `find` y al nombre real de
   tu USB):
   ```bash
   rm -f ~/.local/share/mx.latercia.pos/latercia.sqlite-wal ~/.local/share/mx.latercia.pos/latercia.sqlite-shm
   cp /media/pos/KINGSTON/latercia.sqlite ~/.local/share/mx.latercia.pos/latercia.sqlite
   ```
   *(Los `-wal`/`-shm` son restos de la sesión anterior; hay que borrarlos
   para que no mezclen datos de la base vacía con la nueva.)*
4. Abre la app de nuevo → debe aparecer **todo el catálogo real**. Si sigue
   viéndose vacía, copiaste a una ruta distinta de la que usa la app —
   repite el `find` y compara.

**Opción B — por la propia app (si llevaste un respaldo exportado):** abre la
app → PIN admin → Configuración → Respaldo → **Restaurar** → elige el archivo
del USB → la restauración se aplica al reiniciar la app.

⚠️ En cualquiera de las dos: verifica después productos, precios y empleados
antes de seguir — este es el momento de detectar un archivo equivocado, no el
día de la primera venta.

### 3.4 Permisos de impresión (haz esto ya, aunque la impresora se conecte después)

```bash
sudo usermod -aG lp,lpadmin pos
```
- `lp`: permite escribir directo al dispositivo USB de la impresora
  (`/dev/usb/lp0`).
- `lpadmin`: permite administrar CUPS (dar de alta impresoras en la Fase 5)
  sin ser root.

⚠️ Los grupos se aplican **al iniciar sesión**, no en caliente. Cierra sesión
y vuelve a entrar (o reinicia). Verifica después:
```bash
groups
# → pos adm cdrom sudo ... lp lpadmin  ← deben aparecer lp y lpadmin
```

---

# FASE 4 — Autologin y modo kiosko

> ⚠️ **Usuario de este manual:** todos los comandos de aquí en adelante usan
> `pos` como usuario del kiosko. Si en tu instalación (Fase 1.3) usaste otro
> nombre (en la instalación real del 18-jul fue `latercia`), **sustituye
> `pos` por tu usuario real en TODO — rutas, `chown`, nombres de sesión, todo.**
> Es la causa más común de "no existe el archivo" en esta fase.

### 4.1 Aprende la ruta de escape ANTES de activar nada

En modo kiosko no hay escritorio ni menús. La única puerta trasera son las
**TTY**: consolas de texto que Linux siempre tiene abiertas "detrás" de la
pantalla gráfica.

**Practícalo AHORA, con el escritorio aún disponible:**
1. Presiona `Ctrl+Alt+F3`. La pantalla cambia a texto negro con
   `latercia-caja1 login:`.
2. Teclea `pos`, Enter, tu contraseña (no se ve), Enter. Ya estás en una
   terminal de texto plena.
3. Teclea `exit`, Enter, y regresa al gráfico con **`Ctrl+Alt+F2`** (en la
   instalación real esa fue la tecla que funcionó — `F1` NO regresó a la
   sesión gráfica en ese hardware; pruébalas las dos, varía por equipo).

No sigas hasta que esto te haya funcionado. Es tu salvavidas.

### 4.2 ¿Un monitor o dos? — decide el método de kiosko

La app puede abrir **una sola ventana** (POS, con la cocina en una pestaña
dentro de la misma pantalla) o **dos ventanas separadas** (POS + una ventana
aparte de Cocina·KDS, pensada para un segundo monitor en la cocina). Si el
sitio tiene **dos monitores** (uno para caja, otro para cocina — el caso más
común en un local con área de preparación separada), usa **4.3 (wmctrl)**.
Si es **un solo monitor**, usa **4.3-alt (cage)**, más simple.

⚠️ **Lección de la instalación real:** se intentó primero con `cage` (el
compositor "de una sola app") también para el caso de dos monitores, y
**no funciona para eso** — `cage` trata los dos monitores físicos como si
fueran un solo lienzo gigante, no hay forma de decirle "esta ventana va en
el monitor 1, esta otra en el monitor 2". Por eso el método con dos
monitores usa el escritorio normal + un script que acomoda cada ventana con
`wmctrl`, no `cage`.

### 4.3 Dos monitores (RECOMENDADO si aplica) — escritorio normal + `wmctrl`

**1) Instala las herramientas de acomodo de ventanas:**
```bash
sudo apt install -y wmctrl xdotool
```
⚠️ Escribe el comando completo — un typo real del día de instalación fue
escribir `sudo apt wmctrl xdotool` (sin la palabra `install`), que da un
error confuso ("no tiene sentido la opción «l»") que no deja claro cuál es
el problema real.

**2) Identifica tus monitores** (con los dos ya conectados):
```bash
xrandr --listmonitors
```
Verás algo como:
```
Monitors: 2
 0: +*VGA-0 1280/338x1024/270+0+0  VGA-0
 1: +DisplayPort-1 1360/300x768/230+1280+0  DisplayPort-1
```
Anota: el **nombre** de cada salida (`VGA-0`, `DisplayPort-1` — varía según
tu tarjeta/cableado), su **resolución** (`1280x1024`, `1360x768`) y su
**posición** (`+0+0` el primero, `+1280+0` el segundo — el número tras el
`+` es dónde empieza en X, así que el segundo monitor normalmente arranca
donde termina el ancho del primero). Estos datos son los que vas a usar en
el paso 4 — **van a ser distintos en cada instalación**, no copies los
números de este ejemplo a ciegas.

**3) Prueba manual antes de automatizar nada.** Corre la app en el
escritorio normal:
```bash
/opt/latercia/latercia &
```
Deben abrir dos ventanas flotando en el mismo monitor (normal, todavía no
las acomodamos). Confirma sus nombres exactos:
```bash
wmctrl -l
# → debe listar algo como:
#   0x... 0 jaime-virtualbox LaTercia POS
#   0x... 0 jaime-virtualbox Cocina — LaTercia KDS
```
Con esos nombres y los datos del paso 2, pruébalo a mano (ajusta resolución
y posición a LO QUE TE DIO TU `xrandr`, no copies estos números):
```bash
wmctrl -r "LaTercia POS" -e 0,0,0,1280,1024
wmctrl -r "Cocina — LaTercia KDS" -e 0,1280,0,1360,768
```
Si cada ventana se movió a su monitor correspondiente, los datos son
correctos — ciérralas (`killall latercia`) y sigue al paso 4.

**4) Crea el script que hace esto solo al arrancar.**

⚠️⚠️ **Antes de teclear nada: usa `nano` con el teclado físico de la PC,
NUNCA copies/pegues este script desde un visor de documentos como Okular.**
En la instalación real, pegar comandos desde un `.txt` abierto en Okular
insertó caracteres invisibles (separadores de párrafo Unicode) que rompieron
el script DOS VECES antes de detectar la causa — el error se veía como
"No existe el archivo o el directorio" o "error de sintaxis cerca de
'then'" sin ninguna pista de que el problema era el texto pegado, no el
comando. Tecleado a mano en `nano` funcionó a la primera. Si de verdad
necesitas copiar texto largo desde otra máquina, pásalo por USB como
archivo `.sh` ya escrito (no como texto para pegar), o límpialo primero con:
```bash
tr -d '\r' < origen.sh | python3 -c "import sys; print(sys.stdin.read().replace(chr(8233),'').replace(chr(8232),''))" > limpio.sh
```

```bash
nano ~/kiosk-launch.sh
```
Pega esto (ajustando las coordenadas de las dos líneas `wmctrl -r ... -e` a
las de TU `xrandr --listmonitors` del paso 2 — el resto no cambia):
```bash
#!/bin/bash
sleep 5

APP="/opt/latercia/latercia"

if ! pgrep -f "$APP" > /dev/null; then
  "$APP" &
fi

for i in $(seq 1 30); do
  POS_WIN=$(wmctrl -l | grep "LaTercia POS")
  KDS_WIN=$(wmctrl -l | grep "Cocina")
  if [ -n "$POS_WIN" ] && [ -n "$KDS_WIN" ]; then
    break
  fi
  sleep 1
done

sleep 2

wmctrl -r "LaTercia POS" -e 0,0,0,1280,1024
wmctrl -r "LaTercia POS" -b add,fullscreen

wmctrl -r "Cocina" -e 0,1280,0,1360,768
wmctrl -r "Cocina" -b add,fullscreen
```
Guarda (`Ctrl+O`, Enter, `Ctrl+X`) y hazlo ejecutable:
```bash
chmod +x ~/kiosk-launch.sh
```
**Verifica que quedó limpio** (sin caracteres raros — debe terminar cada
línea justo en el texto, sin nada más):
```bash
cat -A ~/kiosk-launch.sh | head -5
# cada línea debe terminar en $ pegado al último caracter visible,
# NO en algo como M-bM-^@M-)$ (eso sería el separador de Okular colado)
```

**5) Pruébalo a mano** antes de conectarlo al arranque automático:
```bash
killall latercia 2>/dev/null
~/kiosk-launch.sh
```
Espera ~7 segundos — la app debe abrir sola y las dos ventanas deben
acomodarse cada una en su monitor, a pantalla completa.

**6) Conéctalo al inicio de sesión** (arranca solo cuando alguien inicia
sesión gráfica — lo combinamos con autologin en 4.5):
```bash
mkdir -p ~/.config/autostart
nano ~/.config/autostart/kiosk-launch.desktop
```
Teclea/pega esto (5 líneas, ajusta `Exec=` a tu usuario real si no es `pos`):
```
[Desktop Entry]
Type=Application
Name=La Tercia Kiosk Launch
Exec=/home/pos/kiosk-launch.sh
X-LXQt-Need-Tray=false
NoDisplay=true
```
Guarda (`Ctrl+O`, Enter, `Ctrl+X`).
⚠️ Si tu usuario no es `pos`, corrige la ruta `Exec=` de arriba a la real
(`/home/TU_USUARIO/kiosk-launch.sh`).

**Prueba con logout/login manual ANTES de activar autologin** (cierra sesión
desde el menú y vuelve a entrar con tu contraseña) — debe acomodarse solo,
sin que hayas corrido el script a mano. Si funciona, sigue a **4.5**
(saltando 4.3-alt).

### 4.3-alt Un solo monitor (alternativa más simple) — `cage`

Si el sitio solo tiene un monitor (todo en una sola ventana/pestaña), `cage`
sigue siendo la opción más simple — un compositor de una sola app, sin
necesitar el script de `wmctrl`.

```bash
sudo apt install -y cage
cage -- /opt/latercia/latercia
```
- **Si abre la app a pantalla completa:** perfecto, sigue con la sesión
  **normal** en el paso siguiente.
- **Si da pantalla negra, error de renderer, o se cierra solo** (común en
  GPUs integradas viejas): prueba el modo por software:
  ```bash
  LIBGL_ALWAYS_SOFTWARE=1 cage -- /opt/latercia/latercia
  ```
  Si así abre (animaciones menos fluidas, pero operativo), usa esa variante.
- **Si NINGUNA abre:** no actives autologin todavía; lee el error en la
  terminal antes de seguir.

Crea la(s) sesión(es) kiosko. Primero la normal:
```bash
sudo nano /usr/share/wayland-sessions/latercia-kiosk.desktop
```
Teclea/pega (5 líneas):
```
[Desktop Entry]
Name=La Tercia Kiosko
Comment=POS
Exec=cage -- /opt/latercia/latercia
Type=Application
```
Guarda (`Ctrl+O`, Enter, `Ctrl+X`). Ahora la variante software:
```bash
sudo nano /usr/share/wayland-sessions/latercia-kiosk-software.desktop
```
Teclea/pega (5 líneas):
```
[Desktop Entry]
Name=La Tercia Kiosko (software rendering)
Comment=POS — fallback sin GPU
Exec=env LIBGL_ALWAYS_SOFTWARE=1 cage -- /opt/latercia/latercia
Type=Application
```
Guarda igual. Con las dos creadas, en 4.5 usa `Session=latercia-kiosk` o
`Session=latercia-kiosk-software` según cuál abrió bien arriba.

### 4.3-tv Pantallas que son TVs: imagen cortada o resolución rara

Cuando la pantalla de cocina es una **TV** (no un monitor de PC), aparecen dos
problemas muy típicos. **No son bugs de la app** — la app dibuja bien; el
problema está en cómo la TV/el cable/el adaptador manejan la señal. Identifica
tu síntoma:

- **Caso 1 (overscan):** la imagen se ve casi bien pero **los bordes están
  recortados** — se pierde el reloj y "N pedidos activos" del encabezado, los
  botones de la esquina (Recall, All-day) se cortan, todo parece "hecho zoom".
- **Caso 2 (resolución de emergencia):** la imagen se ve **muy deforme /
  estirada / borrosa**, y al abrir la app el diálogo **"¿En qué pantalla?"**
  reporta esa TV como **640×480** (o `xrandr` solo ofrece `640x480` en esa
  salida). Esto es más grave que el overscan y es un problema **distinto**.

---

**Caso 1 — Overscan (bordes recortados).**

Las TVs de consumo por defecto aplican overscan a las entradas **HDMI** —
recortan y amplían ~3-5% la imagen, porque asumen que es video. Las entradas
**VGA** las tratan como "modo PC" y las muestran 1:1, sin recortar (por eso al
pasar de un adaptador DP→VGA a uno DP→HDMI puede empezar a cortarse).

**Arreglo A — en la TV (HAZLO PRIMERO, no toca la PC).** En el control remoto,
entra al ajuste de **tamaño/formato de imagen** y ponlo en modo **1:1 sin
escalar**. El nombre varía por marca:
- **Toshiba:** *Imagen* → "Tamaño de imagen"/"Formato" → **Native / Dot by Dot
  / Real / Nativo / Pantalla completa (Full)**. Truco: renombrar la entrada
  HDMI a **"PC"** a veces fuerza el 1:1 por sí solo.
- **Philips:** "Formato de imagen" → **Sin escalar (Unscaled)**.
- **Genérico (Samsung/LG/otras):** **"Just Scan" / "Screen Fit" / "Ajuste de
  pantalla" / "1:1"**.

**Arreglo B — en Linux** (solo si la TV no tiene esa opción, método de dos
monitores X11/wmctrl). Compensás con *underscan*:
```bash
xrandr --output DP-1 --set underscan on \
       --set "underscan hborder" 32 --set "underscan vborder" 32
```
Sube/baja `32` hasta que entre completa. (Cambia `DP-1` por tu salida real —
ver abajo cómo se llama.)

---

**Caso 2 — Resolución de emergencia 640×480 (EDID no leído). ⭐ El más común
con TVs.**

**Qué pasa:** Linux no pudo leer el **EDID** de la TV (los datos que la
pantalla le manda a la PC diciendo "soy de tal resolución"). Cuando no lo lee,
el sistema se rinde y cae a la resolución de emergencia **640×480**, y la TV
estira esa mini-imagen a la fuerza. El menú de la TV **no lo arregla** porque
el problema no es overscan, es la resolución equivocada.

**Por qué no se lee el EDID:** casi siempre por un **splitter HDMI barato** o
un **adaptador DP→HDMI pasivo** en medio — no dejan pasar el canal de datos
(DDC/EDID) de la TV. Un splitter, además, tiene que armar un EDID único que
sirva para las dos teles, y los baratos no lo hacen → 640×480.

**Ojo con el nombre de la salida:** Lubuntu nombra las salidas por el **puerto
físico de la tarjeta de video**, no por el cable. Un adaptador **DP→HDMI sigue
apareciendo como `DP-x`** (`DP-0`, `DP-1`, `DisplayPort-1`…), NO como `HDMI`,
porque para la GPU el puerto es DisplayPort. El "HDMI" solo existe de la mitad
del cable en adelante.

**Arreglo — forzar la resolución desde la PC** (método de dos monitores,
X11/wmctrl). En una terminal de esa estación:

1. Identifica la salida de la TV — la que **NO** es la del POS (1280×1024) y
   que muestra `640x480`:
   ```bash
   xrandr        # busca la salida `connected` con 640x480, p.ej. DP-1
   ```
2. Crea el modo **1080p** (sincronía estándar de TV) y aplícalo — cambia
   `DP-1` por tu salida real:
   ```bash
   xrandr --newmode "1920x1080_60" 148.50 1920 2008 2052 2200 1080 1084 1089 1125 +hsync +vsync
   xrandr --addmode DP-1 "1920x1080_60"
   xrandr --output DP-1 --mode "1920x1080_60"
   ```
3. **Si alguna TV se queda en "no signal"** (teles viejas/chicas 720p, o dos
   teles distintas colgadas de un splitter que no coinciden), usa **720p**,
   que aceptan todas:
   ```bash
   xrandr --newmode "1280x720_60" 74.25 1280 1390 1430 1650 720 725 730 750 +hsync +vsync
   xrandr --addmode DP-1 "1280x720_60"
   xrandr --output DP-1 --mode "1280x720_60"
   ```
4. Reabre la pantalla del KDS ("¿En qué pantalla?") — la TV debe verse
   completa y reportar la nueva resolución.

**Dejarlo permanente** (si no, al reiniciar vuelve a 640×480). Pega esas 3
líneas al inicio de `~/kiosk-launch.sh`, **después del `sleep 5` y antes de
lanzar la app**, y **ajusta la línea de `wmctrl` de la ventana de Cocina** a la
resolución nueva (el `-e` de "Cocina" debía cuadrar con lo forzado):
```bash
sleep 5
# --- forzar resolución de la TV (EDID no leído) ---
xrandr --newmode "1920x1080_60" 148.50 1920 2008 2052 2200 1080 1084 1089 1125 +hsync +vsync 2>/dev/null
xrandr --addmode DP-1 "1920x1080_60" 2>/dev/null
xrandr --output DP-1 --mode "1920x1080_60"
# ... (resto del script) ...
# y más abajo, la ventana de Cocina a 1920x1080 en la posición del 2º monitor:
#   wmctrl -r "Cocina" -e 0,1280,0,1920,1080
```
(El `2>/dev/null` en `--newmode`/`--addmode` evita ruido cuando el modo ya
existe en arranques posteriores.)

> **Con splitter (una entrada → dos teles):** desde la PC hay **una sola
> salida que forzar** (la del DP→splitter); el splitter reparte la misma señal
> a las dos teles. Elige una resolución que **ambas** acepten (1080p, o 720p
> como apuesta segura).

**Arreglo de raíz (para que "solo funcione" sin script):** un **splitter con
EDID correcto** (algunos traen un switch de EDID manual a 1080p) o un
**adaptador DP→HDMI activo** de mejor marca. Con eso la PC vuelve a leer la
resolución real y no hace falta forzar nada.

⚠️ **Lección de la instalación real (2026-07):** estación con **1 VGA + 2 DP**.
El VGA daba el POS a 1280×1024 (perfecto). Un DP con **adaptador DP→HDMI** iba
a un **splitter Steren** que duplicaba la cocina en **dos TVs** (Toshiba +
Philips). Las dos salían **cortadas/deformes**; el menú de la TV NO lo arregló.
El diálogo "¿En qué pantalla?" delató la causa: la segunda pantalla estaba en
**640×480** — el splitter (y el adaptador pasivo) no pasaban el EDID. Se
resolvió **forzando 1080p con `xrandr`** como arriba. Detalle que confunde: la
salida se llamaba `DP-x`, no `HDMI`, aunque el cable terminara en HDMI.

### 4.4 Confirmar el gestor de sesión

```bash
cat /etc/X11/default-display-manager
```
- `→ /usr/bin/sddm` (lo esperado en Lubuntu 24.04, confirmado en la
  instalación real): continúa en 4.5.
- **Ramificación — dice `gdm3`** (Ubuntu normal con GNOME): el autologin se
  configura distinto. Edita `/etc/gdm3/custom.conf`:
  ```bash
  sudo nano /etc/gdm3/custom.conf
  ```
  y bajo `[daemon]` deja:
  ```
  AutomaticLoginEnable=true
  AutomaticLogin=pos
  ```
  (guardar en nano: `Ctrl+O`, Enter; salir: `Ctrl+X`).
- **Ramificación — dice `lightdm`:**
  ```bash
  sudo mkdir -p /etc/lightdm/lightdm.conf.d
  sudo nano /etc/lightdm/lightdm.conf.d/50-autologin.conf
  ```
  Teclea/pega (3 líneas):
  ```
  [Seat:*]
  autologin-user=pos
  autologin-session=lubuntu
  ```
  (o `latercia-kiosk`/`latercia-kiosk-software` si usaste 4.3-alt). Guarda
  (`Ctrl+O`, Enter, `Ctrl+X`) y salta a 4.6.

### 4.5 Autologin con SDDM

**Si usaste 4.3 (wmctrl, dos monitores):** apunta a la sesión NORMAL del
escritorio (`Lubuntu.desktop` o `lubuntu`, confírmalo con
`ls /usr/share/wayland-sessions/ /usr/share/xsessions/ 2>/dev/null`) — el
autostart que creaste en 4.3 paso 6 es lo que la convierte en kiosko, no una
sesión especial:
```bash
sudo mkdir -p /etc/sddm.conf.d
sudo nano /etc/sddm.conf.d/autologin.conf
```
Teclea/pega (3 líneas):
```
[Autologin]
User=pos
Session=lubuntu
```
Guarda (`Ctrl+O`, Enter, `Ctrl+X`).

**Si usaste 4.3-alt (cage, un monitor):** apunta a tu sesión cage:
```bash
sudo mkdir -p /etc/sddm.conf.d
sudo nano /etc/sddm.conf.d/autologin.conf
```
Teclea/pega (3 líneas):
```
[Autologin]
User=pos
Session=latercia-kiosk-software
```
*(cambia `Session=` a `latercia-kiosk` si te funcionó la variante con GPU).*
Guarda igual.

⚠️ **Punto de no retorno del kiosko:** desde el próximo arranque la PC entra
directa a la app, sin login ni escritorio. Tu vía de reversa es la TTY que ya
practicaste (4.1).

### 4.6 Reiniciar y validar

```bash
sudo reboot
```
La secuencia esperada: logo del fabricante → breve pantalla de arranque →
(con wmctrl: un parpadeo del escritorio de ~7 s mientras se acomodan las
ventanas) → la app de La Tercia a pantalla completa, en su(s) monitor(es).

**Ramificación — arrancó al escritorio normal en vez de la app:**
- Con wmctrl: revisa que `~/.config/autostart/kiosk-launch.desktop` exista y
  que la ruta `Exec=` sea correcta.
- Con cage: el nombre en `Session=` no coincide con el archivo `.desktop`
  (debe ser el nombre del archivo **sin** `.desktop`):
  ```bash
  ls /usr/share/wayland-sessions/
  sudo nano /etc/sddm.conf.d/autologin.conf   # corrige, guarda, reinicia
  ```

**Ramificación — pantalla negra tras el reinicio:** `Ctrl+Alt+F3` → login →
- Con cage: cambia a la sesión software y reinicia:
  ```bash
  sudo sed -i 's/Session=latercia-kiosk$/Session=latercia-kiosk-software/' /etc/sddm.conf.d/autologin.conf
  sudo reboot
  ```
- Si sigue negro, desactiva el kiosko para diagnosticar con calma:
  ```bash
  sudo rm /etc/sddm.conf.d/autologin.conf
  sudo reboot
  ```
  (arranca al escritorio normal; repite 4.2/4.3 mirando el error).

**Ramificación — la app crasheó y quedó pantalla negra/vacía estando en
producción:** ni cage ni el autostart de wmctrl reinician la app sola si
truena. Apagar y encender la PC la restaura (el arranque completo la vuelve
a lanzar). Si esto pasara seguido, hay un plan con reinicio automático vía
systemd (`~/linux_kiosk/latercia-kiosk.service`, instrucciones en sus
comentarios) — pero es otro método, no se combina con 4.3/4.3-alt.

---

# FASE 5 — Hardware, configuración y cierre

### 5.1 Configuración de negocio dentro de la app

*(La app ya viene prediseñada para La Tercia; aun así verifica en sitio:)*

1. Entra con PIN **`0000`** (admin) → Administración.
2. **Cambia el PIN del admin** (Admin → Empleados) — `0000` y `1234` son
   públicos, están en estos manuales. Obligatorio.
3. Crea/verifica los cajeros reales con sus PINs.
4. Verifica negocio, IVA, moneda, pie de ticket, catálogo y precios.
5. **Configuración → Respaldo:** backup automático **ON**.

### 5.2 Impresora — primero identifica qué tienes

Las térmicas ESC/POS se conectan de dos formas. Identifícala:
- Si le sale un **cable de red (RJ45, como de internet)** al router → es de
  **red** → sección 5.3.
- Si le sale un **cable USB** a la PC → es **USB** → sección 5.4.
- (Si tiene ambos puertos, usa **red**: más simple y sin permisos.)

### 5.3 Impresora de RED

**Paso 1 — averiguar su IP.** Tres formas, en orden de facilidad:

a) **Autotest de la impresora** (funciona en casi todas las térmicas: Epson,
   Bixolon, genéricas 58/80mm): apágala, **mantén presionado el botón FEED**
   (el de avanzar papel) y enciéndela sin soltarlo; suelta a los 2–3 s.
   Imprime una página de configuración que incluye la **IP address**.
b) **Panel del router:** entra a la administración del router del local
   (típicamente `192.168.1.1` o `192.168.0.1` en un navegador), busca la
   lista de dispositivos conectados y localiza la impresora.
c) **Escanear la red desde la PC:**
   ```bash
   sudo apt install -y nmap
   ip addr show | grep "inet "     # anota tu red, p.ej. 192.168.1.34/24
   nmap -p 9100 --open 192.168.1.0/24
   # (ajusta 192.168.1 a tu red real)
   ```
   La IP que aparezca con el puerto `9100/tcp open` es la impresora.

**Paso 2 — verificar conectividad ANTES de configurar la app:**
```bash
nc -zv IP_DE_LA_IMPRESORA 9100
# → "Connection to ... 9100 port [tcp/*] succeeded!"
```
Si dice `refused` o `timed out`: la IP está mal, la impresora está apagada, o
no están en la misma red. Resuélvelo aquí — la app no puede arreglar eso.

**Paso 3 — recomendado: fijar la IP de la impresora.** Lo ideal es una
**reserva DHCP** en el panel del router (para la MAC de la impresora, que
sale en el mismo autotest) — pero en la práctica **muchos routers
domésticos/genéricos (Tenda y similares) no la exponen de forma clara**, o
la esconden en un menú confuso. Si no la encuentras en 5 minutos, no pierdas
más tiempo ahí — la impresora casi siempre trae su propia forma de fijar IP
estática desde su panel/menú de configuración (revisa el manual del modelo).
Si tampoco, la app funciona igual con DHCP mientras la IP no cambie sola —
solo confirma la IP actual (Paso 1) cada vez que reinicies el router.

⚠️ **Cuidado con el filtro MAC de routers Tenda:** en la sección "Gestión del
dispositivo" hay un botón **"Añadir"** bajo una columna que dice **"Lista
negra"** — a simple vista parece la forma de "agregar" una reserva, pero es
lo opuesto: agrega la MAC a una **lista negra que le QUITA el acceso a
internet** a ese dispositivo. Si tu impresora (o la PC) deja de responder en
la red justo después de tocar el panel del router, revisa
**Configuración avanzada → Filtrar la dirección MAC** y quita cualquier MAC
que hayas agregado por accidente.

**Paso 4 — configurar la app:** Configuración → Impresión → activa
impresión → transporte **"red"** → dirección: la IP (o `IP:9100`) → ancho de
papel 58 u 80 mm según la impresora → **"Imprimir ticket de prueba"**.

### 5.4 Impresora USB

**Paso 1 — confirmar que Linux la ve.** Con la impresora conectada y
encendida:
```bash
lsusb
```
Busca una línea con la marca (`Epson`, `BIXOLON`, `STMicroelectronics`,
`Winbond` o similar en genéricas). Si dudas cuál es, corre `lsusb` con la
impresora desconectada y luego conectada — la línea nueva es ella.

```bash
ls -l /dev/usb/
# → lo esperado: crw-rw---- 1 root lp ... lp0
```

**Ramificación — no existe `/dev/usb/lp0`:** revisa cómo la registró el
kernel:
```bash
sudo dmesg | tail -20
```
Si menciona `usblp` con otro número (`lp1`), usa ese. Si no menciona nada al
conectarla, prueba otro cable/puerto USB. Si la impresora aparece en `lsusb`
pero nunca crea `lp0`, no expone la clase estándar de impresora — en ese caso
**usa la vía CUPS de abajo de todos modos**, que la maneja por su driver usb
propio.

**Paso 2 — dar de alta la cola RAW en CUPS.** (Necesitas el grupo `lpadmin`
de la Fase 3.4 ya aplicado — verifica con `groups`.)

**Vía recomendada — línea de comandos** (un kiosko normalmente no trae
navegador instalado; esto evita depender de uno):
```bash
lpinfo -v | grep usb
# → algo como: direct usb://STMicroelectronics/USB%20POS%20Printer...
```
Copia esa URI completa (tal cual, con los `%20` y todo) y créala como cola
**raw** con `lpadmin` (ojo: el comando es `lpadmin`, no `lpandmin` — un typo
fácil que da "orden no encontrada" sin pista de qué falló):
```bash
sudo lpadmin -p termica -E -v "usb://STMicroelectronics/USB%20POS%20Printer%20%20%20%20%20%20%20%20" -m raw
```
(cambia la URI por la que te dio TU `lpinfo -v` — la marca/modelo varía).
`-p termica` es el nombre de la cola (el mismo que usarás en la app), `-E`
la habilita, `-m raw` es justo el modo crítico — nunca un driver "de
verdad": si CUPS intenta traducir a lenguaje de impresora de documentos, la
térmica imprime basura o nada, porque la app ya manda bytes ESC/POS listos.

**Alternativa — con navegador, si sí hay uno instalado:**
1. Ve a `http://localhost:631` → pestaña **Administration** → **Add Printer**
   (usuario/contraseña: tu usuario y su contraseña de sistema).
2. En "Local Printers" elige tu térmica → Continue.
3. **Name:** `termica` (sin espacios, este nombre se usa en la app) → Continue.
4. **Make:** `Raw` (hasta arriba de la lista) → Continue → **Model:**
   `Raw Queue (en)` → Add Printer → deja las opciones por defecto.

**Paso 3 — probar la cola desde terminal, antes que la app:**
```bash
echo -e "PRUEBA LA TERCIA\n\n\n\n" | lp -d termica -o raw
# → request id is termica-1 (1 file(s))
```
Deben salir esas palabras en el papel. Si el comando dice OK pero **no sale
papel**: revisa papel/tapa/luz de error de la impresora, y el estado de la
cola:
```bash
lpstat -p termica
# "enabled"/"idle" = bien; si dice "disabled":
cupsenable termica
```
> Nota de comportamiento conocida: la vía CUPS reporta éxito cuando
> **encola** el trabajo, no cuando sale el papel. Impresora apagada = la app
> dirá "enviado" igual. En las pruebas, confirma siempre a ojo.

**Paso 4 — configurar la app:** Configuración → Impresión → transporte
**"usb"** → dirección: `termica` (el nombre de la cola, tal cual) → ticket de
prueba.

**Alternativa sin CUPS (escritura directa):** en la app, transporte "usb" y
dirección `/dev/usb/lp0`. Requiere el grupo `lp` (Fase 3.4). Es más directa
pero menos tolerante; usa CUPS como primera opción y esta como plan B.

**Gaveta de dinero** (si hay): se conecta con su cable RJ11 a la impresora
térmica → en la app: Configuración → Impresión y gaveta → activa gaveta.
Prueba: cobra una venta en efectivo → la gaveta debe abrir con el pulso.

### 5.5 Botonera ESP32 (Wi-Fi / WebSocket, puerto 8080)

La app levanta el servidor de la botonera **al abrir la pantalla del KDS**;
el ESP32 (firmware ya grabado) se conecta solo al puerto **8080** de la PC.

1. **Misma red:** el ESP32 y la PC deben estar en la misma red del local
   (el ESP32 en el Wi-Fi; la PC puede estar por cable al mismo router — eso
   cuenta como misma red).
2. **IP de la PC:**
   ```bash
   ip addr show | grep "inet " | grep -v 127.0.0.1
   # → inet 192.168.1.34/24 ...  ← esta es la IP de la PC
   ```
3. **Fija esa IP en la PC** — más confiable que depender de una reserva DHCP
   del router (en la práctica, muchos routers domésticos ni la exponen
   claramente, y algunos hasta le asignan una IP distinta a la PC entre
   reinicios sin avisar). Usa `nmcli` sobre tu conexión (mira su nombre con
   `nmcli connection show`, normalmente "Conexión cableada 1" si es por
   cable):
   ```bash
   sudo nmcli connection modify "Conexión cableada 1" ipv4.addresses 192.168.1.34/24
   sudo nmcli connection modify "Conexión cableada 1" ipv4.gateway 192.168.1.1
   sudo nmcli connection modify "Conexión cableada 1" ipv4.dns "8.8.8.8,1.1.1.1"
   sudo nmcli connection modify "Conexión cableada 1" ipv4.method manual
   sudo nmcli connection down "Conexión cableada 1"
   sudo nmcli connection up "Conexión cableada 1"
   ```
   (ajusta la IP/gateway a tu red real — usa una IP que esté FUERA del rango
   que reparte el DHCP del router, para que no choque con otro dispositivo).
   Verifica: `ip addr` debe mostrar la IP fija, y `ping 192.168.1.1` (tu
   gateway) debe responder. Apunta el firmware del ESP32 a esta IP.
4. **Firewall:** Ubuntu/Lubuntu trae `ufw` **inactivo** por defecto —
   verifica y solo actúa si está activo:
   ```bash
   sudo ufw status
   # "inactive" → no hagas nada.
   # "active"   → sudo ufw allow 8080/tcp
   ```
5. **Prueba física:** abre la pantalla del KDS en la app, pulsa un botón de
   la botonera → debe sonar la alerta/verse el evento en el KDS.

**Ramificación — la botonera no responde:**
- Verifica que el ESP32 encendió y se conectó al Wi-Fi (LED según tu
  firmware).
- Desde la PC, confirma que el servidor está escuchando (con la pantalla
  del KDS **abierta**):
  ```bash
  ss -tlnp | grep 8080
  # → LISTEN 0 ... 0.0.0.0:8080 ... latercia
  ```
  Si no aparece: la pantalla del KDS no está abierta, u otra instancia tomó
  el puerto (revisa el log del día en `~/Documentos/latercia/logs/`).
- **Truco útil:** `sudo lsof -i :8080` muestra si hay una conexión
  `ESTABLISHED` desde la IP del ESP32 — si aparece, la botonera SÍ está
  hablando con la PC (el problema estaría en la app o en el hardware físico
  del botón, no en la red). Si no aparece ninguna conexión, el problema es
  de red/firmware, no de la app.
- Si el servidor escucha pero el ESP32 no llega: el firmware apunta a otra
  IP (¿cambió la IP de la PC? — ver punto 3), o el router tiene "AP/client
  isolation" activado (búscalo en la config Wi-Fi del router y desactívalo —
  esa opción bloquea la comunicación entre dispositivos de la misma red).

### 5.6 Prueba de fuego (flujo completo, en modo kiosko real)

Con todo conectado, apaga y enciende la PC y corre una operación completa
como si fuera un día real:

1. La PC arranca sola en la app. ✔
2. Login de cajero → abrir turno.
3. Crear una venta con productos reales → mandar a cocina.
4. La comanda **sale impresa** y/o aparece en el KDS. ✔
5. (Si hay botonera) pulsar el botón → el KDS reacciona. ✔
6. Cobrar en efectivo → (si hay gaveta) la gaveta abre. ✔ → ticket impreso. ✔
7. Cerrar turno → corte Z → **imprimir el corte Z**. ✔
8. Configuración → Respaldo → verificar que existe un backup de hoy en la
   lista.
9. Configuración → Equipo → **Reiniciar** → la PC vuelve sola a la app. ✔

### 5.7 Soporte remoto — deja AnyDesk instalado (acceso desatendido)

Como parte del setup, **instala AnyDesk** en la estación para poder dar soporte
sin ir en persona (ajustar pantallas, editar el script del kiosko, revisar
logs). Configurar el **acceso desatendido ahora** evita que en una futura
urgencia tengas que dictarle la instalación por teléfono a un cliente no
técnico. (Ver el **Apéndice B** para el detalle y el caso remoto.)

⚠️ Requiere que la estación sea **X11** (método de dos monitores, Fase 4.3)
para poder **controlar**, no solo ver. Si quedó en `cage`/Wayland (un monitor),
AnyDesk solo verá — revisa el Apéndice B.

En una terminal (lo haces tú, con teclado; en la Lubuntu mínima no hay
navegador, por eso el `.deb` se baja con `wget`):
```bash
sudo apt update
sudo apt install -y wget
cd /tmp
wget https://deb.anydesk.com/pool/main/a/anydesk/anydesk_8.0.4_amd64.deb
sudo apt install -y ./anydesk_8.0.4_amd64.deb
```
(Si esa URL da 404, saca el `_amd64.deb` más nuevo de
`https://deb.anydesk.com/pool/main/a/anydesk/` y ajusta la versión.)

Configura el **acceso desatendido** y deja el servicio activo al arrancar:
```bash
echo "UNA_CONTRASEÑA_FUERTE" | sudo anydesk --set-password
sudo systemctl enable --now anydesk
anydesk --get-id            # anota este número de 9 dígitos
```
Apunta el **ID** y la **contraseña** en la hoja de entrega (guárdala bien: es
acceso total a la caja registradora). Para dar soporte, te conectas desde tu
AnyDesk con ese ID + contraseña, **sin que el cliente tenga que tocar nada**.

### 5.8 Checklist final de entrega (marca todo antes de irte)

- [ ] SO instalado y actualizado; red del local conectada (cable o Wi-Fi).
- [ ] BIOS: "Restore on AC Power Loss" = **Power On** (probado: desconecta el
      cable de corriente con la PC encendida, reconéctalo → la PC debe
      encender sola y llegar hasta la app).
- [ ] Pila CMOS verificada (hora del BIOS correcta tras desconectar) o
      cambiada; zona horaria y NTP correctos (`timedatectl`).
- [ ] Suspensión bloqueada (`systemctl mask sleep.target...`, Fase 2.4).
- [ ] App en `/opt/latercia/`, arranca sin errores.
- [ ] Kiosko: la PC enciende directo en la app, sin escritorio.
- [ ] Ruta de escape por TTY **probada por ti en esta PC** (no solo leída).
- [ ] PIN admin cambiado; cajeros reales creados; PINs anotados con el dueño.
- [ ] Impresora imprime ticket y comanda **físicamente verificados**.
- [ ] IP de la PC fijada (`nmcli`, 5.5) y/o de la impresora reservada en el
      router si fue posible (5.3).
- [ ] Botonera ESP32 probada (si ya está instalada).
- [ ] Backup automático ON + **copia inicial a USB** de
      `/home/pos/Documentos/latercia/backups/`.
- [ ] Flujo completo 5.6 ejecutado sin errores.
- [ ] El dueño sabe: su PIN, abrir/cerrar turno, corte Z, y que
      **apagar/reiniciar es desde Configuración → Equipo** (no hay botón de
      apagar del sistema visible).
- [ ] Contraseña del usuario del kiosko **NO es trivial** (nada tipo `1234`
      o `0000` — se usa para `sudo` y para el mantenimiento por TTY).
- [ ] **AnyDesk** instalado + acceso desatendido configurado (5.7); ID y
      contraseña de AnyDesk anotados en la hoja de entrega.
- [ ] Hoja de entrega con: contraseña del usuario, IP de la PC, IP de
      la impresora, nombre de la cola CUPS (si aplica), **ID + contraseña de
      AnyDesk**.

---

# FASE 6 — Actualizaciones

A partir de la versión instalada en esta visita, la app trae un **módulo de
actualizaciones integrado** (Configuración/Administración → **Quiosco** →
sección **"Actualizaciones"**). Ya no hace falta entrar por terminal a
reemplazar archivos a mano — se hace desde la propia pantalla, con
verificación de integridad y respaldo automático antes de aplicar.

⚠️ **Ojo:** la instalación que ya está en el sitio (hecha el 18-jul, antes de
que existiera este módulo) **no lo tiene todavía**. La primera vez que
actualices esa PC, hay que hacer un paso especial — ver **6.2 Transición
única** más abajo. De ahí en adelante, siempre usas el flujo normal (6.1).

## 6.1 Flujo normal (de aquí en adelante, para cualquier actualización futura)

**En tu VM (o donde compiles):**

1. Sube el código con `git pull` (o trae los cambios como sea que lo hagas).
2. **Sube el número de versión** en dos lugares — deben quedar iguales:
   - `pubspec.yaml`, línea `version:`.
   - `lib/core/utils/app_version.dart`, la constante `appVersion`.
   (No hay un solo lugar automático todavía; si olvidas uno de los dos, la
   app seguirá reportando la versión vieja aunque el código sí se actualizó.)
3. Compila el bundle:
   ```bash
   cd ~/LaTercia
   flutter clean
   flutter pub get
   flutter build linux --release
   ```
4. **Genera el manifiesto** del paquete (usa el mismo número que pusiste en
   el paso 2):
   ```bash
   dart run tool/generate_update_manifest.dart \
       build/linux/x64/release/bundle 1.1.0
   ```
   Debe terminar con algo como:
   ```
   Listo: build/linux/x64/release/bundle/update_manifest.json
     Versión: 1.1.0
     Archivos: 31
   ```
   Este comando corre como Dart puro (no necesita `flutter run` ni la app
   abierta) — calcula un checksum de cada archivo del bundle, para que la
   app del cliente pueda verificar que el paquete llegó completo e intacto
   antes de aplicarlo.
5. Copia la **carpeta `bundle/` completa** (ahora con el `update_manifest.json`
   adentro) a un USB.

**En la PC del cliente:**

6. Conecta el USB. Entra a la app con el PIN de admin → **Administración →
   Quiosco** → baja hasta **"Actualizaciones"**.
7. **"Buscar paquete"** → en el selector de carpetas, navega hasta la carpeta
   `bundle` dentro del USB y **ábrela** (quédate dentro de ella, viendo su
   contenido — `data`, `lib`, etc. — y dale "Abrir" ahí; no selecciones un
   archivo suelto, es la carpeta completa la que se elige).
8. La pantalla debe mostrar **Versión instalada** (la actual), **Versión del
   paquete** (la que acabas de generar) y el aviso verde **"✓ Más nueva que
   la instalada — se puede aplicar."** Si dice que es igual o anterior, el
   botón "Aplicar" queda deshabilitado — revisa que subiste bien el número de
   versión en el paso 2.
9. **"Aplicar actualización"** → confirma en el diálogo (avisa que se hace un
   respaldo automático antes de aplicar, y recomienda no cobrar mientras se
   aplica — ciérrale el turno de caja antes si puedes).
10. Al terminar, sale un diálogo **"Actualización aplicada"** con botón
    **"Reiniciar ahora"** — dale clic. La app se cierra y vuelve a abrir sola
    ya con la versión nueva.

**Qué pasa detrás (por si algo sale raro):** antes de tocar la instalación
activa, la app copia el paquete nuevo a una carpeta temporal y verifica sus
checksums otra vez; solo si todo cuadra, respalda la carpeta actual como
`/opt/latercia.backup-<numero-largo>` y pone la nueva en su lugar — los dos
pasos son renombrados de carpeta (instantáneos, no una copia larga a medio
camino). Si el último paso fallara por cualquier motivo, la app **restaura
sola** el respaldo automáticamente — nunca debería quedar la PC sin una app
funcional.

**Ramificación — "Paquete corrupto o incompleto":** algún archivo no coincide
con el manifiesto (el USB se dañó en el camino, o se copió a medias). No
aplica nada — la instalación activa queda intacta. Vuelve a copiar la carpeta
`bundle/` completa al USB (asegúrate de esperar a que termine de copiar antes
de sacar el USB) e intenta de nuevo.

**Ramificación — quiero volver a la versión anterior (aplicaste pero algo no
te convenció):** la pantalla todavía no tiene un botón para esto — hay que
hacerlo por terminal, con la app cerrada:
```bash
Ctrl+Alt+F3                          # entra a una TTY
# Averigua el nombre exacto del respaldo (hay uno por cada actualización que
# hayas aplicado; el de timestamp más alto es el más reciente):
ls -d /opt/latercia.backup-*
sudo mv /opt/latercia /opt/latercia.no-me-gusto-$(date +%s)
sudo mv /opt/latercia.backup-<EL_QUE_ELEGISTE> /opt/latercia
sudo reboot
```

**Mantenimiento — los respaldos no se borran solos:** cada actualización deja
una carpeta `/opt/latercia.backup-<timestamp>` del mismo tamaño que el bundle
(unos cientos de MB). De vez en cuando, en una visita de mantenimiento, revisa
cuántos hay (`ls -d /opt/latercia.backup-*`) y borra los más viejos si el
disco anda apretado — **conserva siempre al menos el más reciente**:
```bash
df -h /opt                           # espacio disponible
sudo rm -rf /opt/latercia.backup-<EL_MAS_VIEJO>
```

## 6.2 Transición única — llevar el sitio a esta versión (próxima visita)

Este paso se hace **UNA sola vez**: la PC del sitio tiene una instalación de
antes de que existiera el módulo de actualizaciones, así que este primer
salto se hace a mano — como la instalación original, más un paso extra
porque esta versión también cambió **dónde vive la base de datos** (antes en
`Documentos`, ahora en la carpeta de soporte de la app). De aquí en adelante,
todas las actualizaciones siguientes usan el flujo normal de 6.1.

⚠️ **Punto de no retorno:** el paso 2 (respaldo) es el que protege el
catálogo/ventas real del negocio. No sigas al paso 3 sin haberlo hecho y
confirmado.

1. **Cierra la app** en el sitio (si está en modo kiosko: `Ctrl+Alt+F3` →
   inicia sesión → `killall latercia` o similar, o simplemente apaga el
   kiosko temporalmente quitando el autologin — ver el Apéndice).

2. **Respalda la base ACTUAL** (la que trae el catálogo/ventas real del
   negocio, en la ruta VIEJA):
   ```bash
   find ~ -iname "latercia.sqlite*" 2>/dev/null
   # esperado: /home/latercia/Documentos/latercia.sqlite (+ -wal / -shm)
   ```
   Copia esos archivos a un USB (o a una carpeta temporal en el propio
   disco, `~/respaldo-antes-de-actualizar/`, si no traes USB a la mano):
   ```bash
   mkdir -p ~/respaldo-antes-de-actualizar
   cp /home/latercia/Documentos/latercia.sqlite* ~/respaldo-antes-de-actualizar/
   ```

3. **Reemplaza el bundle** con el nuevo (compilado con A3/A4/el módulo de
   actualizaciones — el mismo que armaste en 6.1, pasos 1–5):
   ```bash
   sudo cp -r /opt/latercia /opt/latercia.pre-modulo-updates   # respaldo del binario viejo, por si acaso
   sudo rm -rf /opt/latercia
   sudo mkdir -p /opt/latercia
   sudo cp -r /ruta/al/USB/bundle/* /opt/latercia/
   sudo chmod +x /opt/latercia/latercia
   ```

4. **Mueve la base respaldada a la ruta NUEVA.** El nombre de la carpeta sale
   del bundle ID (`mx.latercia.pos` — confírmalo si acaso con
   `grep APPLICATION_ID /opt/latercia/../linux/CMakeLists.txt` desde tu
   checkout, o simplemente usa este valor):
   ```bash
   mkdir -p ~/.local/share/mx.latercia.pos
   cp ~/respaldo-antes-de-actualizar/latercia.sqlite ~/.local/share/mx.latercia.pos/
   # NO copies los -wal/-shm viejos — son restos de la sesión anterior en la
   # ruta vieja; la app crea los suyos nuevos al abrir en modo WAL.
   ```

5. **Abre la app** (`/opt/latercia/latercia`, o reinicia si ya tienes
   autologin/kiosko activo) → **debe cargar el catálogo real**, no vacío.
   Si aparece vacía, revisa que copiaste el `.sqlite` a la ruta exacta del
   paso 4 (un nombre de carpeta con una letra distinta y la app no la
   encuentra, y arranca con una base nueva en blanco).

6. **Confirma las rutas nuevas** están en uso:
   ```bash
   find ~/.local/share/mx.latercia.pos -type f
   # esperado: latercia.sqlite (+ -wal / -shm que la app acaba de crear)
   find ~/Documentos/latercia -type f
   # esperado (tras la primera venta/backup): logs/... y backups/...
   ```

7. Corre la **prueba de fuego** de 5.6 completa antes de dar por buena la
   transición (venta → cocina → cobro → corte Z → backup).

A partir de aquí, la próxima vez que haya una actualización, se hace con el
flujo normal de **6.1** — ya no hace falta repetir nada de esto.

---

# Apéndice — Mantenimiento y emergencias (para el técnico futuro)

**Salir del modo kiosko para dar mantenimiento:**
```
Ctrl+Alt+F3                                  → consola de texto
login: pos   +   contraseña                  → entrar
sudo rm /etc/sddm.conf.d/autologin.conf      → desactivar autologin
sudo reboot                                  → arranca a login/escritorio normal
```
Para reactivar el kiosko, recrear el archivo (Fase 4.5) y reiniciar.

**Actualizar la app:** desde esta versión, usa el módulo integrado —
ver **Fase 6** (Configuración → Quiosco → Actualizaciones). Ya no hace falta
copiar archivos a mano; el único caso para hacerlo por terminal es una
emergencia (rollback manual, ver 6.1) o si la pantalla de Actualizaciones
no abre por algún motivo — en ese caso extremo, el método a mano sigue
siendo válido:
```bash
sudo cp -r /opt/latercia /opt/latercia.anterior   # respaldo del binario actual
sudo cp -r /ruta/al/USB/bundle/* /opt/latercia/
sudo reboot
```
Los datos NO se tocan (viven fuera del bundle). Si el bundle nuevo falla,
restaurar: `sudo rm -rf /opt/latercia && sudo mv /opt/latercia.anterior /opt/latercia`.

**Rutas importantes (desde la transición de la Fase 6.2 — bundle ID
`mx.latercia.pos`):**
- Base de datos: `~/.local/share/mx.latercia.pos/latercia.sqlite`
  (confírmala con `find ~ -name "latercia.sqlite"` si dudas).
- Logs (uno por día, purga automática 30 días / tope 50 MB):
  `~/Documentos/latercia/logs/`
- Backups: `~/Documentos/latercia/backups/`
- Respaldos de actualizaciones aplicadas: `/opt/latercia.backup-<timestamp>`
  (uno por cada actualización aplicada desde el módulo — ver "los respaldos
  no se borran solos" en 6.1).
- Restaurar backup: desde la app, Configuración → Respaldo → Restaurar.

**Recomendación de compra — no-break (UPS):** un no-break chico (~$800–1200
pesos) entre la corriente y la PC+impresora hace dos cosas: aguanta los
micro-cortes de luz típicos de un local (la venta en curso no se interrumpe)
y le da vida extra a un disco duro viejo (los apagones en frío son lo que más
mata discos de esa edad). No es obligatorio — la base de datos y los backups
están diseñados para sobrevivir un apagón — pero es la mejora de fiabilidad
más barata disponible. Si se instala, el ajuste "Power On" del BIOS sigue
aplicando para cuando el no-break se agote.

**Actualizaciones del sistema:** Ubuntu instala parches de seguridad solo
(`unattended-upgrades`), sin reiniciar por su cuenta — no estorba al kiosko y
conviene dejarlo. En visitas de mantenimiento, aprovecha para un
`sudo apt update && sudo apt upgrade -y` completo desde la TTY.

**Diagnóstico rápido si "no imprime":**
```bash
nc -zv IP_IMPRESORA 9100        # red: ¿responde el puerto?
lpstat -p                        # usb/cups: ¿cola habilitada?
lpq -P termica                   # ¿trabajos atorados?  limpiar: cancel -a termica
```

**Diagnóstico rápido si "la botonera no jala":**
```bash
ss -tlnp | grep 8080             # ¿el POS está escuchando? (KDS abierto)
ip addr show | grep "inet "      # ¿la IP de la PC sigue siendo la reservada?
sudo lsof -i :8080                # ¿hay una conexión ESTABLISHED del ESP32?
                                  # (si aparece, la botonera SÍ está hablando
                                  # con el POS aunque no se vea/oiga nada en
                                  # pantalla — el problema estaría en la app,
                                  # no en la red; revisa el log del día)
```

---

# Apéndice B — Soporte remoto a la estación (AnyDesk)

Para atender a un cliente **sin ir en persona** (ajustar resolución, editar el
script del kiosko, revisar logs, etc.). La idea: que el cliente instale
**AnyDesk** una sola vez y te lea su número; de ahí en adelante tú tecleas todo
tú mismo desde tu PC, sin dictarle comandos.

**Por qué AnyDesk y no TeamViewer:** en una PC **comercial** (un local),
TeamViewer suele marcar "uso comercial" y **cortar la sesión a los 5 minutos** —
te deja a medias. AnyDesk es más ligero en Lubuntu y menos quisquilloso.

**Requisito clave — tiene que ser X11:** el control remoto **solo deja
controlar** (mouse/teclado) si la estación corre en **X11**. El método de **dos
monitores (Fase 4.3, escritorio + `wmctrl`) es X11 → funciona**. El método de
**un monitor (4.3-alt, `cage`) es Wayland → AnyDesk solo VE, no controla**. Si
la estación es `cage` y necesitas control, tendrás que pasarla temporalmente al
escritorio normal o trabajar por otra vía (SSH).

**Sin navegador:** la Lubuntu mínima del cliente normalmente **no trae
navegador**, así que AnyDesk se instala **100% desde la terminal** (nada de
descargar un `.deb` a mano).

### B.1 Guion para el cliente (desde salir del kiosko hasta darte el número)

Mándaselo por **WhatsApp** (mejor que dictarlo por voz — así copia los comandos
tal cual):

1. **Salir del kiosko:** en el POS, **Configuración → Kiosko → apagar "Modo
   kiosko"**. Aparece el escritorio de Lubuntu y la barra de tareas.
   - *Si la ventana no se libera* (porque en esa estación se fuerza fullscreen
     con `wmctrl`, no con el flag de la app): `Ctrl+Alt+F3` → login → editar a
     mano; o usa el atajo del gestor de ventanas para minimizar. Resuélvelo en
     vivo según cómo quedó esa estación.
2. **Abrir terminal:** menú de inicio → Herramientas del sistema → **QTerminal**.
3. **Instalar AnyDesk** — teclear renglón por renglón (la contraseña de `sudo`
   **no muestra nada al escribirla**, es normal):
   ```bash
   sudo apt update
   sudo apt install -y wget
   cd /tmp
   wget https://deb.anydesk.com/pool/main/a/anydesk/anydesk_8.0.4_amd64.deb
   sudo apt install -y ./anydesk_8.0.4_amd64.deb
   anydesk
   ```
4. Al abrir AnyDesk, el cliente te lee el **número de 9 dígitos** (su dirección).
   - *Si la ventana no abre bien* en el escritorio minimalista, saca el número
     por terminal: `anydesk --get-id`.
5. Tú metes ese número en tu AnyDesk (de Windows/Mac) → al cliente le sale un
   aviso → **Aceptar**. Listo, tomas el control.

### B.2 Notas de mantenimiento

- **La versión del `.deb` cambia con el tiempo.** Si el `wget` da "no
  encontrado", saca el nombre actual del archivo del repositorio oficial:
  `https://deb.anydesk.com/pool/main/a/anydesk/` (usa el `_amd64.deb` más nuevo)
  y ajusta la URL. `apt install -y ./archivo.deb` instala **y resuelve
  dependencias** en un paso (no uses `dpkg -i` suelto: deja dependencias rotas).
- **Acceso desatendido (para visitas repetidas, sin que el cliente tenga que
  dar "Aceptar" cada vez):** una vez instalado, en la terminal del cliente:
  ```bash
  echo "UNA_CONTRASEÑA_FUERTE" | sudo anydesk --set-password
  sudo systemctl enable --now anydesk   # deja el servicio corriendo al arrancar
  ```
  Guarda esa contraseña; con ella te conectas sin intervención del cliente.
  ⚠️ Ponla **fuerte** — es acceso total a la caja registradora.
- Terminado el soporte, si activaste acceso desatendido y no lo quieres
  permanente, quítalo: `sudo systemctl disable --now anydesk`.
