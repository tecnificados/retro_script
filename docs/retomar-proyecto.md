# Guía para retomar el proyecto

Lee primero `README.md`, `docs/estado-del-proyecto.md` y `docs/flujo-setup.md`. Después revisa los scripts, el CSV y el último `setup.log`; estas notas no sustituyen el estado real de los archivos.

## Situación al dejarlo

- Jazz Jackrabbit está en la lista fija `$Downloads` de `setup-retro-portable.ps1`, con la fuente de DOS Games Archive. El lanzador de Jazz configura el sonido con `SETUP.EXE` la primera vez, detectando `SOUNDCRD.INF`, y luego ejecuta `JAZZ.EXE`.
- Los juegos extra se declaran en `extra_games.csv`, con el esquema `Title;DownloadUrl;Executable;Year`. Las tres primeras columnas son obligatorias; el año es opcional. Todas las filas usan el mismo flujo, sin reglas especiales por título: extracción en carpeta propia y `.bat` que ejecuta el archivo o ruta relativa declarada.
- `Executable` puede ser uno o varios nombres/rutas relativas dentro del ZIP, separados por comas. El lanzador ejecuta cada comando en ese orden dentro de una sola sesión DOSBox. Si un nombre aparece más de una vez, indicar la ruta; no se permiten rutas absolutas ni `..`.
- El flujo genérico puede ejecutar varios archivos declarados, en orden. No automatiza opciones interactivas del instalador ni permite añadir argumentos.
- El año se guarda en los metadatos locales de ES-DE. El proveedor de scraping es el que el usuario configure en ES-DE; no asumir que MobyGames está disponible.
- `metadata_sources.csv` contiene el nombre exacto del `.bat`, la página de metadatos y una URL directa de imagen opcional. El setup descarga las imágenes antes de copiarlas, conserva los originales en `.setup-cache\metadata-images`, convierte GIF a PNG y monta los resultados en `.setup-cache\metadata-staging` antes de copiarlos a ES-DE. Si una fuente no responde, el setup continúa con título/año locales.
- El usuario confirmó que la descarga y visualización de las imágenes ya funciona. Si vuelve a fallar, revisar `setup.log` y el contenido de `.setup-cache\metadata-images` y `.setup-cache\metadata-staging`.
- Tet42 está en el CSV con la URL de Archive.org, la secuencia `SETUP.EXE,TET.EXE` y año 1989. La copia de trabajo actual contiene el ZIP, ambos ejecutables y el lanzador generado con los dos comandos en ese orden; falta confirmar el juego en ejecución.
- Beneath a Steel Sky está en el catálogo fijo de ScummVM con el ZIP freeware oficial `bass-cd-1.2.zip`. El setup usa sus archivos de datos directamente y ES-DE lo inicia con subtítulos en castellano y voces en inglés.
- Extreme Pinball usa `Games\ExtremePinball\dosbox-video.conf` para estirar la imagen a la pantalla; esto puede deformar las proporciones.
- Break Machine usa el ZIP de Internet Archive y la caché `break-machine-freeware-v14-archive-org.zip`.
- `clean.bat` conserva scripts, documentación, licencia y CSV; borra la instalación y caché tras pedir confirmación.
- El usuario realiza los commits. No hacer commits ni push.
- Si falla la descarga, extracción o detección de un juego, el setup debe registrar un aviso, omitir su lanzador y su entrada de ES-DE, y continuar con los demás juegos. ES-DE y DOSBox son requisitos; no aplicar esta tolerancia a sus descargas base.

## Próximos pasos

1. Probar Tet42 desde ES-DE. Si falla, revisar su log de lanzamiento y adaptar la secuencia al contenido real del ZIP.
2. Si se cambia el proceso, actualizar `README.md` y esta guía.

## Convenciones

- Trabajar dentro de `D:\git\retro_script`.
- Responder en español y conservar caracteres UTF-8.
- No cambiar URLs proporcionadas por el usuario sin razón verificada.
- No afirmar que un juego está instalado o funciona antes de comprobarlo.
