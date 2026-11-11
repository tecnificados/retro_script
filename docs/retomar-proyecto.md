# Guía para retomar el proyecto

Lee primero `README.md`, `docs/estado-del-proyecto.md` y `docs/flujo-setup.md`. Después revisa los scripts, el CSV y el último `setup.log`; estas notas no sustituyen el estado real de los archivos.

## Situación al dejarlo

- Jazz Jackrabbit está en la lista fija `$Downloads` de `setup-retro-portable.ps1`, con la fuente de DOS Games Archive. El lanzador de Jazz configura el sonido con `SETUP.EXE` la primera vez, detectando `SOUNDCRD.INF`, y luego ejecuta `JAZZ.EXE`.
- Los juegos extra se declaran en `extra_games.csv`, con el esquema `Title;DownloadUrl;Executable;Year`. Las tres primeras columnas son obligatorias; el año es opcional. Todas las filas usan el mismo flujo, sin reglas especiales por título: extracción en carpeta propia y `.bat` que ejecuta el archivo o ruta relativa declarada.
- `Executable` puede ser un nombre o una ruta relativa dentro del ZIP. Si el nombre aparece más de una vez, indicar la ruta; no se permiten rutas absolutas ni `..`. El lanzador monta la raíz extraída del juego, conservando el acceso a sus subcarpetas y archivos auxiliares.
- El flujo genérico espera un ejecutable DOS que se inicie directamente. No ejecuta automáticamente instaladores ni configura argumentos o pasos iniciales.
- El año se guarda en los metadatos locales de ES-DE. El proveedor de scraping es el que el usuario configure en ES-DE; no asumir que MobyGames está disponible.
- Tet42 está en el CSV con la URL proporcionada de Archive.org, ejecutable `TET.EXE` y año 1989. El setup se intentó el 11-11-2026, pero falló al resolver `archive.org`; el ZIP aún no está en caché ni instalado. Conservar la URL y reintentar con DNS/red funcionales.
- Beneath a Steel Sky fue retirado por petición del usuario. No reintroducirlo ni añadir montaje de imágenes de CD para ese caso.
- Extreme Pinball usa `Games\ExtremePinball\dosbox-video.conf` para estirar la imagen a la pantalla; esto puede deformar las proporciones.
- Break Machine usa el ZIP de Internet Archive y la caché `break-machine-freeware-v14-archive-org.zip`.
- `clean.bat` conserva scripts, documentación, licencia y CSV; borra la instalación y caché tras pedir confirmación.
- El usuario realiza los commits. No hacer commits ni push.

## Próximos pasos

1. Ejecutar `setup-retro-portable.bat` y revisar `setup.log`.
2. Confirmar que Tet42 se extrae con `Games\Extras\tet42\TET.EXE`, y que su `.bat` ejecuta `TET.EXE` y la entrada de `gamelist.xml` contiene el año 1989.
3. Probar Tet42 desde ES-DE. Si falla, revisar su log de lanzamiento y adaptar el lanzador al contenido real del ZIP.
4. Si se cambia el proceso, actualizar `README.md` y esta guía.

## Convenciones

- Trabajar dentro de `D:\git\retro_script`.
- Responder en español y conservar caracteres UTF-8.
- No cambiar URLs proporcionadas por el usuario sin razón verificada.
- No afirmar que un juego está instalado o funciona antes de comprobarlo.
