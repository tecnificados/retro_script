# Estado del proyecto

Última revisión: 18 de noviembre de 2026.

## Objetivo

Preparar desde Windows una colección portable de juegos DOS y aventuras ScummVM usando ES-DE como interfaz, DOSBox Staging para los juegos DOS y ScummVM para las aventuras compatibles. La instalación se genera desde el setup, guarda un registro y reutiliza las descargas válidas de la caché.

## Catálogo fijo del setup

| Componente o juego | Paquete configurado | Datos de catálogo | Portal de descarga |
| --- | --- | --- | --- |
| ES-DE | Portable 3.5.0 | Interfaz y gamelist de Windows | [ES-DE](https://packages.es-de.org/) |
| DOSBox Staging | 0.83.0 | Emulador DOS | [GitHub Releases](https://github.com/dosbox-staging/dosbox-staging/releases) |
| ScummVM | Portable 2026.4.0 | Motor para aventuras gráficas compatibles | [ScummVM Downloads](https://www.scummvm.org/en/downloads/) |
| Break Machine | Shareware; paquete configurado: edición freeware v1.4 | 1995 | [Internet Archive](https://archive.org/download/break-machine-freeware-v14/break-machine-freeware-v14.zip) |
| Extreme Pinball | Demo | 1995 | [DOSGames.com](https://dosgames.com/files/DOSBOX_EXTREMEPINBALL.ZIP) |
| DOOM | Shareware | 1993 | [DOSGames.com](https://dosgames.com/files/DOSBOX_DOOM.ZIP) |
| Prince of Persia | Demo jugable | 1990 | [DOSGames.com](https://dosgames.com/files/pop1.zip) |
| Hexxagon | Shareware | 1993 | [DOSGames.com](https://dosgames.com/files/hexx.zip) |
| One Must Fall 2097 | Freeware, versión completa | 1994; requiere instalación DOS inicial | [DOSGames.com](https://dosgames.com/files/omf2097.zip) |
| Jazz Jackrabbit | Shareware 1.1 | 1994 | [DOS Games Archive](https://image.dosgamesarchive.com/games/jazz.zip) |
| The Lost Vikings | Demo | 1993 | [DOSGames.com](https://dosgames.com/files/vikings.zip) |
| Worms Reinforcements | Demo | 1995 | [Internet Archive](https://archive.org/download/worms_202611/WORMS.zip) |
| Beneath a Steel Sky | Freeware, edición CD 1.2 | 1994; voces en inglés y subtítulos en castellano | [ScummVM](https://downloads.scummvm.org/frs/extras/Beneath%20a%20Steel%20Sky/bass-cd-1.2.zip) |
| Dráscula: The Vampire Strikes Back | Freeware; base inglesa, complemento de idiomas con español y música en MP3 | 1996 | [ScummVM: juego base](https://downloads.scummvm.org/frs/extras/Drascula_%20The%20Vampire%20Strikes%20Back/drascula-1.0.zip), [complemento multilingüe](https://downloads.scummvm.org/frs/extras/Drascula_%20The%20Vampire%20Strikes%20Back/drascula-int-1.0.zip) y [complemento musical MP3](https://downloads.scummvm.org/frs/extras/Drascula_%20The%20Vampire%20Strikes%20Back/drascula-audio-mp3-2.0.zip) |
| Lure of the Temptress | Freeware, edición española | 1992 | [ScummVM](https://downloads.scummvm.org/frs/extras/Lure%20of%20the%20Temptress/lure-es-1.1.zip) |
| Maniac Mansion Deluxe | Freeware, remake fan-made compatible con ScummVM mediante AGS; se fuerza la traducción española incluida | 2004 | [Internet Archive](https://archive.org/download/mmd_20240815/MMD.zip) |

Los lanzadores DOS se generan con DOSBox a pantalla completa. Extreme Pinball usa un perfil de estiramiento que llena la pantalla panorámica, con posible deformación de proporciones. One Must Fall 2097 ejecuta su instalador DOS una sola vez y espera la ruta predeterminada `C:\OMF`. Cada juego ScummVM tiene una carpeta propia bajo `ROMs\scummvm`, con sus datos y descriptor juntos; la carpeta enlaza al descriptor para lanzarlo directamente desde la lista del sistema. Dráscula incluye las pistas del complemento musical oficial MP3 dentro de `audio`, junto con su base y su complemento de idiomas. Lure y los datos de Maniac Mansion Deluxe se han detectado con ScummVM.

Los portales enlazados son las fuentes de descarga configuradas actualmente. Las categorías identifican la edición incluida y no sustituyen los términos de los titulares. Si un titular o representante comunica una irregularidad, se retirará cuanto antes del proyecto y de las descargas el material afectado.

## Jazz Jackrabbit

Jazz Jackrabbit forma parte de la lista fija `$Downloads` en `setup-retro-portable.ps1` y se instala bajo `Games\JazzJackrabbit`. Su lanzador abre `SETUP.EXE` si no existe `SOUNDCRD.INF`, y después inicia `JAZZ.EXE`.

La ficha de DOS Games Archive identifica `jazz.zip` como Jazz Jackrabbit 1.1, shareware para MS-DOS, año 1994: <https://www.dosgamesarchive.com/download/jazz-jackrabbit/>. En la instalación anterior, el configurador creó `SOUNDCRD.INF`.

## Juegos extra del CSV

`extra_games.csv` usa las columnas `Title;DownloadUrl;Executable;Year`. `Title`, `DownloadUrl` y `Executable` son obligatorios; `Year` es opcional. La fila actual es:

```csv
Tet42;https://archive.org/download/Tet42SW1989EduardKappelA.BanzhafStrategyPuzzle/Tet42.zip;SETUP.EXE,TET.EXE;1989
```

El setup aplica la misma lógica a todas las filas: conserva cada ZIP en caché, extrae cada juego en `Games\Extras\<slug>` y genera un `.bat` que monta la raíz del juego y ejecuta lo declarado en `Executable`. Este campo admite uno o varios nombres o rutas relativas separados por comas; se ejecutan en orden dentro de la misma sesión de DOSBox. No admite rutas absolutas ni `..`; si un nombre sin ruta aparece varias veces, hay que indicar la ruta. Si falta cualquiera de los ejecutables declarados, se omite ese juego.

El año se conserva en el nombre y en los metadatos locales de ES-DE. El scraping usa el proveedor que el usuario configure en ES-DE; el setup no presupone MobyGames ni otro servicio. Aunque un intento anterior no pudo resolver `archive.org`, la copia de trabajo actual contiene el ZIP, `SETUP.EXE`, `TET.EXE` y el lanzador con ambos comandos en ese orden. No se ha confirmado todavía el juego en ejecución.

## Metadatos iniciales

`metadata_sources.csv` define el sistema, la página y una URL directa de imagen opcional por nombre de lanzador. El setup descarga previamente las imágenes a `.setup-cache\metadata-images`, genera el material en `.setup-cache\metadata-staging` y lo copia a ES-DE una vez creados los lanzadores. Los GIF se convierten a PNG; la caché de imágenes se reutiliza al reintentar y `clean.bat` la borra. Un fallo de fuente no detiene el setup. Para un juego extra, añade el nombre exacto del `.bat` generado. Dráscula y Lure usan capturas del sitio de ScummVM; Maniac Mansion Deluxe usa una captura de MobyGames.

La última ejecución confirmada por el usuario mostró correctamente las imágenes preparadas por este flujo en ES-DE.

## Convenciones de trabajo

- Repositorio de trabajo: `D:\git\retro_script`.
- Comunicación y documentación del proyecto: español; conservar UTF-8.
- El usuario hace los commits. No crear commits ni hacer push.
- Las carpetas de distribución y ejecución están ignoradas por Git; consultar `.gitignore` antes de añadir archivos generados.
- Las descargas, extracciones y detecciones de ejecutable de juegos son independientes: si falla una, se registra aviso y se omite ese juego, mientras los demás siguen procesándose. ES-DE y DOSBox continúan siendo necesarios para terminar la instalación.
- `clean.bat` solicita confirmación y borra caché, ES-DE, DOSBox, juegos extraídos, log y lanzador generado. Conserva scripts, documentación, licencia y `extra_games.csv`.
- Al cambiar descargas, catálogo o lanzadores, actualizar este documento y `README.md` si cambia el flujo para el usuario.
