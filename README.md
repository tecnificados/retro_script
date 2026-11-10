# Retro portable para Windows

Este repositorio prepara una instalación portable de **ES-DE** y **DOSBox Staging** para organizar y jugar a juegos DOS desde Windows. El proceso se ejecuta desde un `.bat`, descarga los componentes que faltan, conserva las descargas en una caché local, extrae los paquetes una sola vez, crea los lanzadores y guarda un registro.

## Inicio rápido

1. Descarga o clona este repositorio en una carpeta local de Windows.
2. Ejecuta `setup-retro-portable.bat`. El setup puede tardar mientras descarga ES-DE, DOSBox y los juegos configurados.
3. Cuando termine sin errores, ejecuta `run-retro-portable.bat` para abrir ES-DE.
4. En ES-DE, selecciona un juego y pulsa Intro. Los lanzadores incluidos ejecutan DOSBox a pantalla completa.

Para volver a configurar, vuelve a ejecutar `setup-retro-portable.bat`. Los ZIP válidos de `.setup-cache` se reutilizan.

## Añadir juegos

Los juegos adicionales se declaran en [`juegos-extra.csv`](juegos-extra.csv), en UTF-8 y separado por punto y coma. El encabezado es:

```csv
Title;DownloadUrl;Year
```

Cada fila requiere título y URL directa a un ZIP. El año es opcional y, si se indica, se usa en el nombre mostrado y en los metadatos de ES-DE para ayudar al scraper. Ejemplo actual:

```csv
Jazz Jackrabbit;https://image.dosgamesarchive.com/games/jazz.zip;1994
```

El setup descarga el ZIP en `.setup-cache\extra-<slug>.zip`, lo extrae en `Games\Extras\<slug>`, busca un `.EXE`, `.COM` o `.BAT` que no parezca instalador y genera un lanzador en la carpeta de ROMs de ES-DE. El ZIP de Jazz Jackrabbit incluye un configurador de sonido: su lanzador lo abre en la primera ejecución y, cuando se guarda la configuración, inicia el juego. El archivo debe contener un ejecutable DOS lanzable directamente; otros paquetes con instaladores o formatos especiales pueden requerir lógica específica.

Después de editar el CSV, ejecuta `setup-retro-portable.bat` otra vez.

## Registro y solución de problemas

- `setup.log`: registro acumulado de descargas y configuración, escrito en UTF-8.
- `ES-DE\ES-DE\logs\es_log.txt`: registro de ES-DE; se activa con `--debug`.
- Cada juego extra tiene además un registro de lanzamiento junto a sus lanzadores.

Si una descarga falla, revisa la URL, la conexión y el error concreto en `setup.log`. Los errores DNS pueden depender del entorno o la red desde la que se ejecuta el setup. Al reintentar, los paquetes completos ya guardados en caché no se descargan de nuevo. Una descarga parcial `.part` se valida antes de reutilizarse.

Si el ZIP se descargó pero no se configuró, revisa si contiene un ejecutable DOS directamente. Si usa un instalador o un formato especial, no añadas una detección genérica que ejecute cualquier `.EXE`: documenta e implementa el flujo de ese juego por separado.

## Archivos y estado del proyecto

- [Estado técnico y catálogo](docs/estado-del-proyecto.md)
- [Flujo del setup, caché y CSV](docs/flujo-setup.md)
- [Guía para retomar el proyecto](docs/retomar-proyecto.md)

Los binarios descargados, juegos extraídos, ES-DE, DOSBox y logs están excluidos de Git mediante `.gitignore`. Se versionan los scripts, `juegos-extra.csv` y esta documentación. El usuario realiza sus propios commits.

## Licencias

El setup descarga componentes y juegos de terceros. Las etiquetas freeware, demo y shareware identifican el tipo de paquete que se seleccionó; no sustituyen la licencia de cada titular. Consulta `LICENSE` para la licencia del contenido propio del repositorio y verifica los términos de cada descarga antes de redistribuirla.
