# Guía para retomar el proyecto

Lee primero `README.md`, `docs/estado-del-proyecto.md` y `docs/flujo-setup.md`. Después revisa los archivos reales del repositorio: las notas de estado no sustituyen la inspección del código ni del log más reciente.

## Situación al dejarlo

- El CSV de juegos extra contiene Jazz Jackrabbit, año 1994, en shareware.
- La URL debe mantenerse exactamente como `https://image.dosgamesarchive.com/games/jazz.zip`.
- El usuario confirmó que la URL funciona.
- Hubo un primer error DNS para `image.dosgamesarchive.com`; un intento posterior descargó el ZIP correctamente. La URL funciona y debe conservarse.
- El ZIP está en caché y el setup generó el lanzador `Jazz Jackrabbit.bat` en ES-DE.
- El ZIP contiene `JAZZ.EXE` y `SETUP.EXE`. El configurador genera `SOUNDCRD.INF`; no genera `CONFIG.000`.
- El script y el lanzador generado usan `SOUNDCRD.INF` como señal para saltar el configurador y arrancar `JAZZ.EXE`.
- Pendiente: confirmar el arranque real de Jazz desde ES-DE.
- Beneath a Steel Sky fue retirado a petición del usuario. No reintroducirlo ni añadir montaje de imágenes de CD para ese caso.
- Los juegos base anteriores siguen definidos dentro del setup.

## Próximo paso útil

Para regenerar la instalación o el lanzador, ejecutar `setup-retro-portable.bat` y revisar `setup.log`. Para cerrar el pendiente de Jazz:

1. Confirmar que existe `Games\Extras\jazz-jackrabbit\SOUNDCRD.INF`.
2. Lanzar Jazz Jackrabbit desde ES-DE: debe saltar el configurador y abrir `JAZZ.EXE`.
3. Si falla, revisar `ES-DE\ES-DE\ROMs\windows\Jazz Jackrabbit launch.log`, corregir el launcher y actualizar este estado.

## Instrucciones de colaboración

- Trabajar dentro de `D:\git\retro_script`.
- Responder al usuario en español y preservar correctamente acentos y caracteres especiales.
- No crear commits ni subir cambios: el usuario se encarga de los commits.
- No reemplazar enlaces proporcionados por el usuario sin una razón comprobada.
- Comunicar los bloqueos de DNS como problemas del entorno donde se ejecutó, salvo evidencia adicional.
- No decir que el juego está instalado o funciona hasta haber verificado el resultado real.
