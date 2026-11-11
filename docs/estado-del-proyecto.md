# Estado del proyecto

Última revisión: 10 de noviembre de 2026.

## Objetivo

Preparar desde Windows una colección portable de juegos DOS usando ES-DE como interfaz y DOSBox Staging como emulador. La instalación debe poder generarse de nuevo ejecutando el setup, registrar sus operaciones y reutilizar las descargas válidas guardadas en caché.

## Componentes configurados

El script `setup-retro-portable.ps1` descarga y configura:

| Componente o juego | Paquete configurado | Datos de catálogo |
| --- | --- | --- |
| ES-DE | Portable 3.5.0 | Interfaz y gamelist de Windows |
| DOSBox Staging | 0.83.0 | Emulador DOS |
| Break Machine | Freeware v1.4 ([ZIP en Internet Archive](https://archive.org/download/break-machine-freeware-v14/break-machine-freeware-v14.zip)) | 1995 |
| Extreme Pinball | Demo | 1995 |
| DOOM | Shareware | 1993 |
| Prince of Persia | Demo jugable | 1990 |
| Hexxagon | Shareware | 1993 |
| One Must Fall 2097 | Versión completa seleccionada | 1994; requiere instalación DOS inicial |
| Jazz Jackrabbit | `juegos-extra.csv`; shareware 1.1 | 1994 |

Los lanzadores incluidos se generan con DOSBox a pantalla completa. Extreme Pinball usa un perfil de estiramiento a pantalla completa para reducir las bandas negras en pantallas panorámicas. One Must Fall 2097 ejecuta su instalador DOS una sola vez y espera la instalación en la ruta predeterminada `C:\OMF`.

## Estado de Jazz Jackrabbit

La fila activa está en `juegos-extra.csv`:

```csv
Jazz Jackrabbit;https://image.dosgamesarchive.com/games/jazz.zip;1994
```

La ficha de DOS Games Archive identifica `jazz.zip` como Jazz Jackrabbit 1.1, shareware para MS-DOS, y muestra el año 1994: <https://www.dosgamesarchive.com/download/jazz-jackrabbit/>.

El ZIP ya está descargado en `.setup-cache` y extraído en `Games\Extras\jazz-jackrabbit`; el lanzador aparece en ES-DE. Se comprobó que el paquete contiene `JAZZ.EXE` y `SETUP.EXE`. El configurador genera `SOUNDCRD.INF` (38 bytes en esta instalación), no `CONFIG.000`. El lanzador comprueba ese archivo después del setup y continúa con `JAZZ.EXE`.

La descarga tuvo primero un error DNS en este entorno; un intento posterior funcionó y el paquete quedó en caché. La primera ejecución creó `SOUNDCRD.INF`, pero una comprobación errónea de `CONFIG.000` interrumpió el lanzador antes del juego. El script y el lanzador generado ya comprueban `SOUNDCRD.INF`; falta confirmar el arranque real de Jazz.

## Convenciones de trabajo

- Repositorio de trabajo: `D:\git\retro_script`.
- Comunicación y documentación del proyecto: español.
- Mantener UTF-8 para texto y CSV; evitar conversiones que estropeen acentos.
- El usuario hace los commits. No crear commits ni hacer push.
- Las carpetas de distribución y ejecución están ignoradas por Git; consulta `.gitignore` antes de añadir archivos generados.
- Al cambiar descargas, catálogo o lanzadores, actualizar este documento y `README.md` si cambia el flujo de usuario.
