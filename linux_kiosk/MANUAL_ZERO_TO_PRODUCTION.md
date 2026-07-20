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
FASE 4                         →  autologin + modo kiosko (cage)
FASE 5                         →  impresora, botonera ESP32, checklist final
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
- GPU integrada vieja (Intel HD de esa época): es probable que `cage`
  necesite el **Plan B de software rendering** (Fase 4.4) — no te asustes si
  pasa, ya está previsto y es el mismo modo que corre en tu VM.
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

Tras el reinicio, terminal de nuevo:
```bash
sudo apt install -y gstreamer1.0-plugins-base gstreamer1.0-plugins-good cups cage
```
Qué es cada cosa:
- `gstreamer...`: sonidos de alerta del KDS.
- `cups`: sistema de impresión (para impresora USB; no estorba si es de red).
- `cage`: el compositor que convierte la PC en "electrodoméstico" (Fase 4).

Verifica que quedaron:
```bash
which cage
# → /usr/bin/cage
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
**apúntalo**: en la Fase 4 irás directo al Plan B (4.4).

### 3.3b Cargar la base de datos con el catálogo real

La primera ejecución (3.3) creó una base **vacía** (con los defaults de
fábrica). Ahora reemplázala por la base buena que traes en el USB-2.

**Opción A — reemplazo directo del archivo:**
1. Cierra la app por completo.
2. Localiza dónde creó la app su base en esta PC:
   ```bash
   find ~ -name "latercia.sqlite*" 2>/dev/null
   # → lo esperado: /home/pos/Documents(o Documentos)/latercia.sqlite
   #   (pueden aparecer también latercia.sqlite-wal / -shm)
   ```
3. Reemplaza (ajusta las rutas a lo que te dio el `find` y al nombre real de
   tu USB):
   ```bash
   rm -f ~/Documents/latercia.sqlite-wal ~/Documents/latercia.sqlite-shm
   cp /media/pos/KINGSTON/latercia.sqlite ~/Documents/latercia.sqlite
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

### 4.1 Aprende la ruta de escape ANTES de activar nada

En modo kiosko no hay escritorio ni menús. La única puerta trasera son las
**TTY**: consolas de texto que Linux siempre tiene abiertas "detrás" de la
pantalla gráfica.

**Practícalo AHORA, con el escritorio aún disponible:**
1. Presiona `Ctrl+Alt+F3`. La pantalla cambia a texto negro con
   `latercia-caja1 login:`.
2. Teclea `pos`, Enter, tu contraseña (no se ve), Enter. Ya estás en una
   terminal de texto plena.
3. Teclea `exit`, Enter, y regresa al gráfico con `Ctrl+Alt+F1` (si F1 no,
   prueba `Ctrl+Alt+F2` — varía según la distro).

No sigas hasta que esto te haya funcionado. Es tu salvavidas.

### 4.2 Probar `cage` a mano

```bash
cage -- /opt/latercia/latercia
```
- **Si abre la app a pantalla completa:** perfecto. Ciérrala desde dentro si
  la app lo permite, o `Ctrl+Alt+F3` → login → `killall latercia cage` →
  `Ctrl+Alt+F1`. Continúa en 4.3 usando la sesión **normal**.
- **Si da pantalla negra, error de renderer, o se cierra solo** (probable en
  esta PC por la GPU vieja): prueba el modo por software:
  ```bash
  LIBGL_ALWAYS_SOFTWARE=1 cage -- /opt/latercia/latercia
  ```
  Si así abre (aunque las animaciones se sientan menos fluidas), usarás la
  sesión **software** en 4.3/4.4. Es exactamente el mismo modo con el que
  corre tu VM — totalmente operativo.
- **Si NINGUNA de las dos abre:** no actives autologin. Lee el error en la
  terminal. Alternativa de emergencia: usa el método "autostart sobre el
  escritorio" (archivos `latercia-kiosk.service` / `.desktop` en
  `~/linux_kiosk/`, instrucciones en `setup.md` §4–5) — muestra el
  escritorio un instante al arrancar, pero funciona sin cage.

### 4.3 Crear las sesiones kiosko (crea LAS DOS, elige una en 4.5)

Sesión normal (GPU):
```bash
sudo tee /usr/share/wayland-sessions/latercia-kiosk.desktop > /dev/null <<'EOF'
[Desktop Entry]
Name=La Tercia Kiosko
Comment=POS
Exec=cage -- /opt/latercia/latercia
Type=Application
EOF
```

Sesión software (fallback sin GPU):
```bash
sudo tee /usr/share/wayland-sessions/latercia-kiosk-software.desktop > /dev/null <<'EOF'
[Desktop Entry]
Name=La Tercia Kiosko (software rendering)
Comment=POS — fallback sin GPU
Exec=env LIBGL_ALWAYS_SOFTWARE=1 cage -- /opt/latercia/latercia
Type=Application
EOF
```

Tener las dos instaladas te deja cambiar de una a otra editando **una sola
línea** (4.5), sin volver a crear archivos.

### 4.4 Confirmar el gestor de sesión

```bash
cat /etc/X11/default-display-manager
```
- `→ /usr/bin/sddm` (lo esperado en Lubuntu 24.04): continúa en 4.5.
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
  (guardar en nano: `Ctrl+O`, Enter; salir: `Ctrl+X`). GDM no permite fijar
  la sesión por archivo de config: al primer arranque con autologin, cierra
  sesión una vez, y en la pantalla de login elige el engrane ⚙ → "La Tercia
  Kiosko" antes de entrar — GDM recuerda la última sesión usada.
- **Ramificación — dice `lightdm`:**
  ```bash
  sudo mkdir -p /etc/lightdm/lightdm.conf.d
  sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf > /dev/null <<'EOF'
  [Seat:*]
  autologin-user=pos
  autologin-session=latercia-kiosk
  EOF
  ```
  (usa `latercia-kiosk-software` si aplica el Plan B) y salta 4.5.

### 4.5 Autologin con SDDM

Usa `Session=latercia-kiosk` **o** `Session=latercia-kiosk-software` según lo
que funcionó en 4.2:

```bash
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null <<'EOF'
[Autologin]
User=pos
Session=latercia-kiosk-software
EOF
```
*(El bloque de arriba deja la variante software, la más probable en esta PC.
Si en 4.2 funcionó la GPU normal, cambia esa línea a
`Session=latercia-kiosk`.)*

⚠️ **Punto de no retorno del kiosko:** desde el próximo arranque la PC entra
directa a la app, sin login ni escritorio. Tu vía de reversa es la TTY que ya
practicaste (4.1).

### 4.6 Reiniciar y validar

```bash
sudo reboot
```
La secuencia esperada: logo del fabricante → breve pantalla de arranque → la
app de La Tercia a pantalla completa. **Nada de escritorio.**

**Ramificación — arrancó al escritorio normal en vez de la app:** el nombre
en `Session=` no coincide con el archivo `.desktop`. El valor debe ser el
nombre del archivo **sin** `.desktop`:
```bash
ls /usr/share/wayland-sessions/
# → latercia-kiosk.desktop  latercia-kiosk-software.desktop
sudo nano /etc/sddm.conf.d/autologin.conf   # corrige, guarda, reinicia
```

**Ramificación — pantalla negra tras el reinicio:** `Ctrl+Alt+F3` → login →
- Si usaste la sesión GPU, cámbiala a la software:
  ```bash
  sudo sed -i 's/Session=latercia-kiosk$/Session=latercia-kiosk-software/' /etc/sddm.conf.d/autologin.conf
  sudo reboot
  ```
- Si ya estabas en software y aun así está negro, desactiva el kiosko para
  diagnosticar con calma:
  ```bash
  sudo rm /etc/sddm.conf.d/autologin.conf
  sudo reboot
  ```
  (arranca al escritorio normal; repite 4.2 mirando el error).

**Ramificación — la app crasheó y quedó pantalla negra estando en
producción:** con cage puro, si la app muere la sesión termina y no se
reinicia sola. Apagar y encender la PC la restaura (el arranque completo la
vuelve a lanzar). Si esto pasara seguido, el plan alterno con reinicio
automático es el servicio systemd de `~/linux_kiosk/latercia-kiosk.service`
(instrucciones en sus comentarios) — pero implica el método autostart, no
cage.

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

**Paso 3 — recomendado: fijar la IP de la impresora.** En el panel del
router, crea una **reserva DHCP** para la MAC de la impresora (la MAC viene
en el mismo autotest). Sin esto, un reinicio del router puede cambiarle la IP
y la impresión "se rompe sola" un día cualquiera.

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

**Paso 2 — vía recomendada: cola RAW en CUPS.** (Necesitas el grupo
`lpadmin` de la Fase 3.4 ya aplicado — verifica con `groups`.)

1. Abre el navegador de la PC (menú → Internet → Firefox) y ve a:
   `http://localhost:631`
2. Pestaña **Administration** → botón **Add Printer**.
   - Si pide usuario/contraseña: usa `pos` y tu contraseña.
3. En "Local Printers" debe aparecer tu térmica (p.ej. "EPSON TM-T20
   (USB)"). Selecciónala → Continue.
4. **Name:** `termica` (sin espacios — este nombre exacto se usa en la app).
   Location y Description: lo que quieras → Continue.
5. **Make:** elige **`Raw`** (hasta arriba de la lista) → Continue.
6. **Model:** `Raw Queue (en)` → **Add Printer**.
7. En las opciones por defecto que siguen, deja todo como está → Set
   Default Options.

⚠️ **Crítico:** el Make/Model debe ser **Raw**. Si eliges un driver "de
verdad", CUPS intentará convertir los trabajos a lenguaje de impresora de
documentos y la térmica imprimirá basura o nada — la app manda bytes ESC/POS
ya listos y necesita que CUPS los pase intactos.

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
3. **Reserva esa IP en el router** (reserva DHCP por MAC, igual que con la
   impresora — la MAC de la PC sale con `ip link show`). Si el firmware del
   ESP32 apunta a una IP fija de la PC y el router se la cambia, la botonera
   muere en silencio.
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
  el puerto (revisa el log del día en
  `~/.local/share/latercia/logs/`).
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

### 5.7 Checklist final de entrega (marca todo antes de irte)

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
- [ ] IPs reservadas en el router (impresora de red y/o PC para la botonera).
- [ ] Botonera ESP32 probada (si ya está instalada).
- [ ] Backup automático ON + **copia inicial a USB** de
      `/home/pos/.local/share/latercia/backups/`.
- [ ] Flujo completo 5.6 ejecutado sin errores.
- [ ] El dueño sabe: su PIN, abrir/cerrar turno, corte Z, y que
      **apagar/reiniciar es desde Configuración → Equipo** (no hay botón de
      apagar del sistema visible).
- [ ] Hoja de entrega con: contraseña del usuario `pos`, IP de la PC, IP de
      la impresora, nombre de la cola CUPS (si aplica).

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

**Actualizar la app:** compilar bundle nuevo (Fase 0), y en la PC:
```bash
sudo cp -r /opt/latercia /opt/latercia.anterior   # respaldo del binario actual
sudo cp -r /media/pos/USB/bundle/* /opt/latercia/
sudo reboot
```
Los datos NO se tocan (viven fuera del bundle). Si el bundle nuevo falla,
restaurar: `sudo rm -rf /opt/latercia && sudo mv /opt/latercia.anterior /opt/latercia`.

**Rutas importantes:**
- Base de datos: `/home/pos/Documents/latercia.sqlite` (o `Documentos/` según
  el idioma del sistema — confírmala con `find ~ -name "latercia.sqlite"`)
- Logs (uno por día, purga automática 30 días / tope 50 MB):
  `/home/pos/.local/share/latercia/logs/`
- Backups: `/home/pos/.local/share/latercia/backups/`
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
```
