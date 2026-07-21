# Logs (bitácora de la app)

Logger a archivo, intencionalmente simple: sin paquete externo, solo líneas de
texto append-only volcadas a disco. Código en `lib/core/utils/app_logger.dart`.

- **Ubicación:** `Documentos/latercia/logs/latercia-YYYY-MM-DD.log` (un archivo
  por día). Van a Documentos —y no a la carpeta interna de la app— para que un
  técnico los encuentre y copie a mano (misma lógica que los backups; la base de
  datos sí vive aparte, ver `docs/datos-y-rutas` cuando exista / `database.dart`).
- **Nunca loguear PINs** (`Employees.pin`) — ver `docs/seguridad.md`.
- **Escritura serializada:** las llamadas concurrentes se encolan para que no se
  entrelacen líneas parciales ni haya carrera al rotar el archivo a medianoche.
- **Logging nunca lanza** hacia el código que lo llama.

## Purga y tope de tamaño

- Retención por antigüedad: **30 días**.
- La purga corre al arrancar **y cada 24 h** mientras el proceso siga vivo. Antes
  corría solo al arrancar; en un kiosko que corre semanas sin reiniciar
  (`Restart=always` reacciona a crashes, no al paso del tiempo) los logs viejos
  se acumulaban hasta el siguiente arranque.
- **Tope duro de tamaño total: 50 MB.** Red de seguridad ante un bug que loguee
  en loop dentro de un mismo día — la purga por antigüedad sola no alcanza en ese
  caso, porque todo el volumen se generó hoy. Si tras purgar por antigüedad el
  total sigue por encima del tope, se siguen borrando los más antiguos hasta
  bajar del tope. El archivo **del día en curso nunca se borra** (el sink activo
  sigue escribiendo ahí); ese caso queda para la siguiente purga.
