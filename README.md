# Retro portable para Windows

Este repositorio prepara una instalación portable de **ES-DE** y **DOSBox Staging** para organizar y jugar a juegos DOS desde Windows. El proceso se ejecuta desde un `.bat`, descarga los componentes que faltan, conserva las descargas en una caché local, extrae los paquetes una sola vez, crea los lanzadores y guarda un registro.

## Inicio rápido

1. Descarga o clona este repositorio en una carpeta local de Windows.
2. Ejecuta `setup-retro-portable.bat`. El setup puede tardar mientras descarga ES-DE, DOSBox y los juegos configurados.
3. Cuando termine sin errores, ejecuta `run-retro-portable.bat` para abrir ES-DE.
4. En ES-DE, selecciona un juego y pulsa Intro. Los lanzadores incluidos ejecutan DOSBox a pantalla completa. Extreme Pinball estira la imagen para ocupar también los lados de una pantalla panorámica; esto puede deformar un poco sus proporciones.

Para volver a configurar, vuelve a ejecutar `setup-retro-portable.bat`. Los ZIP válidos de `.setup-cache` se reutilizan. Para borrar la caché y la instalación descargada o extraída y empezar de cero, ejecuta `clean.bat`; conserva los scripts, la documentación, `extra_games.csv` y `metadata_sources.csv`.

## Juegos incluidos inicialmente

El setup ofrece estos juegos fijos; los paquetes de juego se omiten individualmente si no se pueden descargar o no contienen un ejecutable reconocido:

| Juego | Tipo de versión | Año |
| --- | --- | --- |
| Break Machine | Shareware; el paquete configurado es la edición freeware v1.4 | 1995 |
| Extreme Pinball | Demo | 1995 |
| DOOM | Shareware | 1993 |
| Prince of Persia | Demo jugable | 1990 |
| Hexxagon | Shareware | 1993 |
| One Must Fall 2097 | Freeware, versión completa | 1994 |
| Jazz Jackrabbit | Shareware 1.1 | 1994 |
| The Lost Vikings | Demo | 1993 |

Las categorías describen el paquete incluido o su distribución; no reemplazan los términos de licencia de sus titulares.

## Añadir juegos

Los juegos adicionales se declaran en [`extra_games.csv`](extra_games.csv), en UTF-8 y separado por punto y coma. El encabezado es:

```csv
Title;DownloadUrl;Executable;Year
```

Cada fila requiere título, URL directa a un ZIP y el ejecutable incluido en el ZIP. `Executable` puede ser un nombre como `TET.EXE` o una ruta relativa como `BIN\JUEGO.EXE`; no se permiten rutas absolutas ni segmentos `..`. Si solo se indica un nombre y aparece más de una vez en el ZIP, el setup se detiene y pide la ruta completa. El año es opcional y se usa en el nombre mostrado y en los metadatos locales de ES-DE. Ejemplo actual:

```csv
Tet42;https://archive.org/download/Tet42SW1989EduardKappelA.BanzhafStrategyPuzzle/Tet42.zip;TET.EXE;1989
```

El setup procesa todas las filas con la misma lógica: descarga el ZIP en `.setup-cache\extra-<slug>.zip`, lo descomprime en su carpeta `Games\Extras\<slug>` y genera un lanzador en ES-DE. El lanzador monta la carpeta raíz del juego en DOSBox y ejecuta el archivo indicado en `Executable`, manteniendo disponibles los demás archivos y subcarpetas del ZIP. Si falla la descarga, extracción o detección del ejecutable de un juego, el setup lo omite, lo registra como aviso y sigue con los demás. No hay reglas especiales por juego para las filas del CSV. El año queda como metadato local; el scraping depende del proveedor que tengas configurado en ES-DE. Esta configuración genérica presupone que el ejecutable se puede iniciar directamente; los juegos que necesiten instalador, argumentos o configuración inicial no se preparan automáticamente. Jazz Jackrabbit es un juego fijo del setup y conserva su configuración de sonido de primera ejecución.

El setup también prepara metadatos iniciales desde las páginas indicadas en [`metadata_sources.csv`](metadata_sources.csv). Descarga previamente las imágenes directas a `.setup-cache\metadata-images`, deja el `gamelist.xml` y las imágenes ya preparadas en `.setup-cache\metadata-staging` y después los copia a la instalación portable de ES-DE. Para una fila extra, añade el nombre exacto del `.bat` generado, la página del juego y, opcionalmente, una URL directa de imagen. Se usa esa imagen directa si se indicó; en caso contrario se busca la imagen Open Graph de la página. Los GIF se convierten a PNG y se reutilizan desde caché al reintentar. Título y año siguen procediendo del catálogo local. Si una fuente falla, el setup continúa con los datos locales y lo anota en `setup.log`.

Después de editar el CSV, ejecuta `setup-retro-portable.bat` otra vez.

## Registro y solución de problemas

- `setup.log`: registro acumulado de descargas y configuración, escrito en UTF-8.
- `ES-DE\ES-DE\logs\es_log.txt`: registro de ES-DE; se activa con `--debug`.
- Cada juego extra tiene además un registro de lanzamiento junto a sus lanzadores.

Si una descarga falla, revisa la URL, la conexión y el error concreto en `setup.log`. Los errores DNS pueden depender del entorno o la red desde la que se ejecuta el setup. Al reintentar, los paquetes completos ya guardados en caché no se descargan de nuevo. Una descarga parcial `.part` se valida antes de reutilizarse.

Si el ZIP se descargó pero no se configuró, revisa que `Executable` coincida con un archivo del ZIP. Si está en una subcarpeta, especifica la ruta relativa. El sistema no elige automáticamente un `.EXE` para evitar lanzar por error un instalador o configurador.

## Archivos y estado del proyecto

- [Estado técnico y catálogo](docs/estado-del-proyecto.md)
- [Flujo del setup, caché y CSV](docs/flujo-setup.md)
- [Guía para retomar el proyecto](docs/retomar-proyecto.md)
- [Fuentes de metadatos iniciales](metadata_sources.csv)

ES-DE se navega con teclado o mando; la versión usada no ofrece navegación nativa con ratón. Los binarios descargados, juegos extraídos, ES-DE, DOSBox y logs están excluidos de Git mediante `.gitignore`. Se versionan los scripts, `extra_games.csv` y esta documentación. El usuario realiza sus propios commits.

## Licencias

El setup descarga componentes y juegos de terceros. Las etiquetas freeware, demo y shareware identifican el tipo de paquete que se seleccionó; no sustituyen la licencia de cada titular. Consulta `LICENSE` para la licencia del contenido propio del repositorio y verifica los términos de cada descarga antes de redistribuirla.

## Autoría

Juan Carlos Ballesteros Hermida — Tecnificados — [www.tecnificados.com](https://www.tecnificados.com)
