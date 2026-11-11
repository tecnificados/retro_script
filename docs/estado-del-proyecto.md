# Estado del proyecto

Última revisión: 11 de noviembre de 2026.

## Objetivo

Preparar desde Windows una colección portable de juegos DOS usando ES-DE como interfaz y DOSBox Staging como emulador. La instalación se genera desde el setup, guarda un registro y reutiliza las descargas válidas de la caché.

## Catálogo fijo del setup

| Componente o juego | Paquete configurado | Datos de catálogo | Portal de descarga |
| --- | --- | --- | --- |
| ES-DE | Portable 3.5.0 | Interfaz y gamelist de Windows | [ES-DE](https://packages.es-de.org/) |
| DOSBox Staging | 0.83.0 | Emulador DOS | [GitHub Releases](https://github.com/dosbox-staging/dosbox-staging/releases) |
| Break Machine | Shareware; paquete configurado: edición freeware v1.4 | 1995 | [Internet Archive](https://archive.org/download/break-machine-freeware-v14/break-machine-freeware-v14.zip) |
| Extreme Pinball | Demo | 1995 | [DOSGames.com](https://dosgames.com/files/DOSBOX_EXTREMEPINBALL.ZIP) |
| DOOM | Shareware | 1993 | [DOSGames.com](https://dosgames.com/files/DOSBOX_DOOM.ZIP) |
| Prince of Persia | Demo jugable | 1990 | [DOSGames.com](https://dosgames.com/files/pop1.zip) |
| Hexxagon | Shareware | 1993 | [DOSGames.com](https://dosgames.com/files/hexx.zip) |
| One Must Fall 2097 | Freeware, versión completa | 1994; requiere instalación DOS inicial | [DOSGames.com](https://dosgames.com/files/omf2097.zip) |
| Jazz Jackrabbit | Shareware 1.1 | 1994 | [DOS Games Archive](https://image.dosgamesarchive.com/games/jazz.zip) |
| The Lost Vikings | Demo | 1993 | [DOSGames.com](https://dosgames.com/files/vikings.zip) |

Los lanzadores se generan con DOSBox a pantalla completa. Extreme Pinball usa un perfil de estiramiento que llena la pantalla panorámica, con posible deformación de proporciones. One Must Fall 2097 ejecuta su instalador DOS una sola vez y espera la ruta predeterminada `C:\OMF`.

Los portales enlazados son las fuentes de descarga configuradas actualmente. Las categorías identifican la edición incluida y no sustituyen los términos de los titulares. Si un titular o representante comunica una irregularidad, se retirará cuanto antes del proyecto y de las descargas el material afectado.

## Jazz Jackrabbit

Jazz Jackrabbit forma parte de la lista fija `$Downloads` en `setup-retro-portable.ps1` y se instala bajo `Games\JazzJackrabbit`. Su lanzador abre `SETUP.EXE` si no existe `SOUNDCRD.INF`, y después inicia `JAZZ.EXE`.

La ficha de DOS Games Archive identifica `jazz.zip` como Jazz Jackrabbit 1.1, shareware para MS-DOS, año 1994: <https://www.dosgamesarchive.com/download/jazz-jackrabbit/>. En la instalación anterior, el configurador creó `SOUNDCRD.INF`.

## Juegos extra del CSV

`extra_games.csv` usa las columnas `Title;DownloadUrl;Executable;Year`. `Title`, `DownloadUrl` y `Executable` son obligatorios; `Year` es opcional. La fila actual es:

```csv
Tet42;https://archive.org/download/Tet42SW1989EduardKappelA.BanzhafStrategyPuzzle/Tet42.zip;TET.EXE;1989
```

El setup aplica la misma lógica a todas las filas: conserva cada ZIP en caché, extrae cada juego en `Games\Extras\<slug>` y genera un `.bat` que monta la raíz del juego y ejecuta lo declarado en `Executable`. El campo admite nombre de archivo o ruta relativa dentro del ZIP, pero no rutas absolutas ni `..`; si el nombre aparece varias veces, hay que indicar la ruta. No se elige un ejecutable automáticamente ni se aplican reglas especiales por título. Este flujo está pensado para juegos que se inicien directamente; no instala paquetes que requieran pasos manuales.

El año se conserva en el nombre y en los metadatos locales de ES-DE. El scraping usa el proveedor que el usuario configure en ES-DE; el setup no presupone MobyGames ni otro servicio. El intento del 11 de noviembre de 2026 no pudo resolver `archive.org` desde este entorno, así que no se confirmó que Tet42 se descargara o aparezca en ES-DE. Se conserva la URL proporcionada; reintentar desde una red que resuelva el dominio.

## Metadatos iniciales

`metadata_sources.csv` define una página y una URL directa de imagen opcional por nombre de lanzador. El setup descarga previamente las imágenes a `.setup-cache\metadata-images`, genera el material en `.setup-cache\metadata-staging` y lo copia a ES-DE una vez creados los lanzadores. Los GIF se convierten a PNG; la caché de imágenes se reutiliza al reintentar y `clean.bat` la borra. Un fallo de fuente no detiene el setup. Para un juego extra, añade el nombre exacto del `.bat` generado.

La última ejecución confirmada por el usuario mostró correctamente las imágenes preparadas por este flujo en ES-DE.

## Convenciones de trabajo

- Repositorio de trabajo: `D:\git\retro_script`.
- Comunicación y documentación del proyecto: español; conservar UTF-8.
- El usuario hace los commits. No crear commits ni hacer push.
- Las carpetas de distribución y ejecución están ignoradas por Git; consultar `.gitignore` antes de añadir archivos generados.
- Las descargas, extracciones y detecciones de ejecutable de juegos son independientes: si falla una, se registra aviso y se omite ese juego, mientras los demás siguen procesándose. ES-DE y DOSBox continúan siendo necesarios para terminar la instalación.
- `clean.bat` solicita confirmación y borra caché, ES-DE, DOSBox, juegos extraídos, log y lanzador generado. Conserva scripts, documentación, licencia y `extra_games.csv`.
- Al cambiar descargas, catálogo o lanzadores, actualizar este documento y `README.md` si cambia el flujo para el usuario.
