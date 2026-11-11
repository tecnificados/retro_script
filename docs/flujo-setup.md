# Flujo del setup

## Entrada

- `setup-retro-portable.bat` invoca `setup-retro-portable.ps1` con `-NoProfile` y `ExecutionPolicy Bypass`, captura el código de salida y deja abierta la consola al final.
- El script obtiene la raíz desde `$PSScriptRoot`, por lo que sus rutas de trabajo se resuelven respecto a la ubicación del repositorio.
- `juegos-extra.csv` usa UTF-8 y el delimitador `;`. Las columnas requeridas son `Title` y `DownloadUrl`; `Year` es opcional.

Ejemplo:

```csv
Title;DownloadUrl;Year
Jazz Jackrabbit;https://image.dosgamesarchive.com/games/jazz.zip;1994
```

## Descarga y caché

`Get-Archive` guarda los ZIP en `.setup-cache`. Antes de descargar, comprueba que un archivo existente se pueda abrir como ZIP. Las descargas nuevas usan un sufijo `.part`, que solo se promueve a ZIP definitivo después de validar su estructura. Si algo falla, el error queda en `setup.log`.

Los paquetes base usan nombres estables declarados en `$Downloads`. Los juegos del CSV usan `extra-<slug>.zip`. Una repetición del setup reutiliza ZIP válidos, y `Expand-Once` evita extraer otra vez las carpetas con su marcador `.ready`.

Una URL puede resolver en el equipo del usuario y fallar en otro entorno por DNS o conectividad. No cambiar una URL solo porque una ejecución aislada no pueda resolver su dominio; verificar el error y conservar la fuente solicitada.

## Instalación y lanzamiento

El script extrae ES-DE y DOSBox bajo la carpeta del repositorio. Extrae cada juego en `Games`, busca sus ejecutables y escribe lanzadores `.bat` bajo `ES-DE\...\ROMs\windows`. Los lanzadores construyen rutas relativas desde ES-DE y llevan un log propio. Los lanzadores DOSBox incluidos usan `--fullscreen`. Extreme Pinball también usa un archivo de configuración específico de DOSBox Staging con `aspect = stretch`, `viewport = fit` e `integer_scaling = off` para llenar la pantalla panorámica, a costa de alterar las proporciones de la imagen.

Para cada fila extra:

1. Normaliza el título en un slug para caché y carpeta.
2. Descarga y extrae el ZIP una sola vez.
3. Busca `.EXE`, `.COM` o `.BAT`, evitando nombres típicos de instaladores, configuradores y documentación.
4. Prefiere ejecutables con nombres como `SKY`, `GAME`, `PLAY` o `START`; si no los encuentra, elige según tamaño.
5. Crea un lanzador DOSBox montando la carpeta del ejecutable como `C:`. Para el slug `jazz-jackrabbit`, el lanzador comprueba si existe `SOUNDCRD.INF`; si falta, inicia `SETUP.EXE` a pantalla completa. El usuario debe configurar y guardar el sonido. Cuando `SOUNDCRD.INF` aparece, el lanzador abre `JAZZ.EXE`.
6. Incorpora el juego a `gamelist.xml`. Si `Year` contiene cuatro dígitos, añade el año al nombre y un `releasedate` de primero de enero.

La detección automática no es universal. Un archivo que requiera instalación, argumentos especiales, archivos auxiliares en otra carpeta, CD virtual o configuración adicional necesita una implementación específica. No se debe asumir que cualquier primer ejecutable encontrado sea el juego. Jazz Jackrabbit conserva una excepción explícita por su paso inicial de configuración.

## Archivos de registro y salida

- `setup.log`: registro acumulado del setup, UTF-8 con BOM.
- `ES-DE\...\logs\es_log.txt`: registro de ES-DE; el acceso generado habilita `--debug`.
- `<título> launch.log`: salida del proceso DOSBox para cada juego.
- `run-retro-portable.bat`: acceso a ES-DE, generado por el setup.

## Idempotencia y limpieza

Si se borran `Emulators`, `ES-DE`, `Games` y el acceso de lanzamiento pero se conservan los scripts, el CSV y `.setup-cache`, el setup puede reconstruir la instalación. Si se borra además la caché, volverá a descargar los paquetes.

Al retirar una fila del CSV, comprobar si el setup elimina también el lanzador y la entrada obsoleta de `gamelist.xml`: actualmente el script añade o actualiza los juegos configurados, pero no reconcilia automáticamente todas las filas antiguas que se hayan borrado del CSV. Limpiar manualmente cualquier salida obsoleta generada al retirar un juego o implementar una reconciliación segura antes de depender de ese comportamiento.

## Diagnóstico recomendado

1. Leer el último error de `setup.log`.
2. Separar fallos de DNS/conexión, ZIP inválido, extracción y detección de ejecutable.
3. Revisar el ZIP y el contenido extraído antes de cambiar la lógica del lanzador.
4. Si el setup ya descargó el ZIP, reintentar debe reutilizar la caché.
5. Mantener las rutas relativas y escribir las líneas de `.bat` como ASCII para evitar problemas de consola; mantener PowerShell, CSV y Markdown en UTF-8.
