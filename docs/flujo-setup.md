# Flujo del setup

## Entrada

- `setup-retro-portable.bat` invoca `setup-retro-portable.ps1` con `-NoProfile` y `ExecutionPolicy Bypass`, captura el código de salida y deja abierta la consola al final.
- El script obtiene la raíz desde `$PSScriptRoot`, por lo que sus rutas de trabajo se resuelven respecto a la ubicación del repositorio.
- `extra_games.csv` usa UTF-8 y el delimitador `;`. Las columnas requeridas son `Title`, `DownloadUrl` y `Executable`; `Year` es opcional.

Ejemplo:

```csv
Title;DownloadUrl;Executable;Year
Tet42;https://archive.org/download/Tet42SW1989EduardKappelA.BanzhafStrategyPuzzle/Tet42.zip;TET.EXE;1989
```

## Descarga y caché

`Get-Archive` guarda los ZIP en `.setup-cache`. Antes de descargar, comprueba que un archivo existente se pueda abrir como ZIP. Las descargas nuevas usan un sufijo `.part`, que solo se promueve a ZIP definitivo después de validar su estructura. Si algo falla, el error queda en `setup.log`.

Los paquetes base usan nombres estables declarados en `$Downloads`; Jazz Jackrabbit forma parte de esa lista fija. Los juegos del CSV usan `extra-<slug>.zip`. Una repetición del setup reutiliza ZIP válidos, y `Expand-Once` evita extraer otra vez las carpetas con su marcador `.ready`.

Una URL puede resolver en el equipo del usuario y fallar en otro entorno por DNS o conectividad. No cambiar una URL solo porque una ejecución aislada no pueda resolver su dominio; verificar el error y conservar la fuente solicitada.

## Instalación y lanzamiento

El script extrae ES-DE y DOSBox bajo la carpeta del repositorio. Extrae cada juego en `Games` y, para las filas del CSV, resuelve el ejecutable declarado en `Executable`; después escribe lanzadores `.bat` bajo `ES-DE\...\ROMs\windows`. Los lanzadores construyen rutas relativas desde ES-DE y llevan un log propio. Los lanzadores DOSBox incluidos usan `--fullscreen`. Extreme Pinball también usa un archivo de configuración específico de DOSBox Staging con `aspect = stretch`, `viewport = fit` e `integer_scaling = off` para llenar la pantalla panorámica, a costa de alterar las proporciones de la imagen.

Para cada fila extra:

1. Normaliza el título en un slug para caché y carpeta.
2. Descarga y extrae el ZIP una sola vez.
3. Resuelve el nombre o ruta relativa de `Executable` dentro de la carpeta extraída; si no aparece, detiene el setup con un error claro. Se permiten subcarpetas, pero no rutas absolutas ni segmentos `..`. Si un nombre sin ruta coincide con más de un archivo, pide precisar la ruta.
4. Crea un lanzador DOSBox que monte la raíz de la carpeta del juego como `C:` y ejecute el archivo declarado, conservando así el acceso a los demás archivos y subcarpetas del ZIP.
5. Incorpora el juego a `gamelist.xml`. Si `Year` contiene cuatro dígitos, añade el año al nombre y un `releasedate` de primero de enero. Esto solo proporciona metadatos locales; no configura ni presupone un proveedor de scraping concreto.

Todas las filas del CSV recorren el mismo proceso genérico; no hay condiciones por título. Este proceso presupone que el ejecutable declarado puede abrirse directamente desde DOSBox con la raíz del ZIP montada como `C:`. Los paquetes que necesiten instalación o pasos de configuración no se preparan automáticamente. Jazz Jackrabbit está fuera del CSV, en la lista fija del setup, y mantiene su paso específico de configuración de sonido.

## Archivos de registro y salida

- `setup.log`: registro acumulado del setup, UTF-8 con BOM.
- `ES-DE\...\logs\es_log.txt`: registro de ES-DE; el acceso generado habilita `--debug`.
- `<título> launch.log`: salida del proceso DOSBox para cada juego.
- `run-retro-portable.bat`: acceso a ES-DE, generado por el setup.
- `clean.bat`: confirma y elimina caché, emuladores y juegos extraídos, instalación de ES-DE, log y acceso generado; conserva los scripts, documentos, licencia y CSV.

## Idempotencia y limpieza

Si se borran `Emulators`, `ES-DE`, `Games` y el acceso de lanzamiento pero se conservan los scripts, `extra_games.csv` y `.setup-cache`, el setup puede reconstruir la instalación. Si se borra además la caché, volverá a descargar los paquetes.

Al retirar una fila del CSV, comprobar si el setup elimina también el lanzador y la entrada obsoleta de `gamelist.xml`: actualmente el script añade o actualiza los juegos configurados, pero no reconcilia automáticamente todas las filas antiguas que se hayan borrado del CSV. Limpiar manualmente cualquier salida obsoleta generada al retirar un juego o implementar una reconciliación segura antes de depender de ese comportamiento.

## Diagnóstico recomendado

1. Leer el último error de `setup.log`.
2. Separar fallos de DNS/conexión, ZIP inválido, extracción y detección de ejecutable.
3. Revisar el ZIP y el contenido extraído antes de cambiar la lógica del lanzador.
4. Si el setup ya descargó el ZIP, reintentar debe reutilizar la caché.
5. Mantener las rutas relativas y escribir las líneas de `.bat` como ASCII para evitar problemas de consola; mantener PowerShell, CSV y Markdown en UTF-8.
