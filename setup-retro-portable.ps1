<#
  Configura una instalación portable de ES-DE + DOSBox Staging + demos y freeware DOS.
  Ejecutar desde PowerShell: .\setup-retro-portable.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Root = $PSScriptRoot
$Cache = Join-Path $Root '.setup-cache'
$Log = Join-Path $Root 'setup.log'
$EsdeVersion = '3.5.0'
$DosboxVersion = '0.83.0'
$Downloads = @(
    [pscustomobject]@{ Name='ES-DE'; Url="https://packages.es-de.org/release/$EsdeVersion/ES-DE_${EsdeVersion}-x64_Portable.zip"; Archive='esde.zip' },
    [pscustomobject]@{ Name='DOSBox Staging'; Url="https://github.com/dosbox-staging/dosbox-staging/releases/download/v$DosboxVersion/dosbox-staging-windows-x64-v$DosboxVersion.zip"; Archive='dosbox.zip' },
    [pscustomobject]@{ Name='Break Machine freeware v1.4'; Url='https://archive.org/download/break-machine-freeware-v14/break-machine-freeware-v14.zip'; Archive='break-machine-freeware-v14-archive-org.zip' },
    [pscustomobject]@{ Name='Extreme Pinball demo'; Url='https://dosgames.com/files/DOSBOX_EXTREMEPINBALL.ZIP'; Archive='extreme-pinball-demo.zip' },
    [pscustomobject]@{ Name='DOOM shareware'; Url='https://dosgames.com/files/DOSBOX_DOOM.ZIP'; Archive='doom-shareware-dosbox.zip' },
    [pscustomobject]@{ Name='Prince of Persia playable demo'; Url='https://dosgames.com/files/pop1.zip'; Archive='prince-of-persia-playable-demo.zip' },
    [pscustomobject]@{ Name='Hexxagon shareware'; Url='https://dosgames.com/files/hexx.zip'; Archive='hexxagon-shareware.zip' },
    [pscustomobject]@{ Name='One Must Fall 2097 full version'; Url='https://dosgames.com/files/omf2097.zip'; Archive='one-must-fall-2097-full.zip' },
    [pscustomobject]@{ Name='Jazz Jackrabbit shareware v1.1'; Url='https://image.dosgamesarchive.com/games/jazz.zip'; Archive='jazz-jackrabbit-shareware-v11.zip' }
)

function Write-Log([string]$Message, [string]$Level='INFO') {
    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    $utf8 = New-Object System.Text.UTF8Encoding($true)
    $writer = New-Object System.IO.StreamWriter($Log, $true, $utf8)
    try { $writer.WriteLine($line) } finally { $writer.Dispose() }
    Write-Host $line
}

function Get-Archive([string]$Name, [string]$Url, [string]$File) {
    $path = Join-Path $Cache $File
    $part = "$path.part"
    if (Test-Path -LiteralPath $path) {
        try { $zip = [System.IO.Compression.ZipFile]::OpenRead($path); $null = $zip.Entries.Count; $zip.Dispose(); Write-Log "$Name ya está en caché; se reutiliza."; return $path }
        catch { Remove-Item -LiteralPath $path -Force; Write-Log "Caché incompleta de $Name; se volverá a descargar." 'WARN' }
    }
    if (Test-Path -LiteralPath $part) {
        try {
            $zip = [System.IO.Compression.ZipFile]::OpenRead($part)
            $null = $zip.Entries.Count
            $zip.Dispose()
            Move-Item -LiteralPath $part -Destination $path -Force
            Write-Log "$Name estaba completo en el archivo temporal; se conserva y reutiliza."
            return $path
        }
        catch { Remove-Item -LiteralPath $part -Force; Write-Log "Descarga temporal incompleta de $Name; se iniciará de nuevo." 'WARN' }
    }
    Remove-Item -LiteralPath $part -Force -ErrorAction SilentlyContinue
    Write-Log "Descargando $Name desde $Url"
    Invoke-WebRequest -Uri $Url -OutFile $part -MaximumRedirection 10 -UseBasicParsing
    try { $zip = [System.IO.Compression.ZipFile]::OpenRead($part); $null = $zip.Entries.Count; $zip.Dispose() }
    catch { Remove-Item -LiteralPath $part -Force -ErrorAction SilentlyContinue; throw "La descarga de $Name no parece un ZIP válido. Comprueba la URL o la conexión." }
    Move-Item -LiteralPath $part -Destination $path -Force
    Write-Log "$Name descargado y guardado en caché."
    return $path
}

function Expand-Once([string]$Archive, [string]$Destination, [string]$Marker='.ready') {
    if (Test-Path -LiteralPath (Join-Path $Destination $Marker)) { return }
    $staging = "$Destination.incomplete"
    Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
    Expand-Archive -LiteralPath $Archive -DestinationPath $staging -Force
    if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination -Recurse -Force }
    Move-Item -LiteralPath $staging -Destination $Destination
    New-Item -ItemType File -Path (Join-Path $Destination $Marker) -Force | Out-Null
}

function Get-RelativePath([string]$BaseDirectory, [string]$TargetPath) {
    $baseUri = New-Object System.Uri(($BaseDirectory.TrimEnd('\') + '\'))
    $targetUri = New-Object System.Uri($TargetPath)
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('/', '\')
}

function ConvertTo-SafeSlug([string]$Value) {
    $slug = ($Value.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    if (-not $slug) { throw "No se pudo crear un identificador para el juego: $Value" }
    return $slug
}

try {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    New-Item -ItemType Directory -Path $Cache -Force | Out-Null
    Write-Log 'Inicio de configuración.'
    $extraGamesFile = Join-Path $Root 'extra_games.csv'
    $extraGames = @()
    if (Test-Path -LiteralPath $extraGamesFile) {
        $extraGames = @(Import-Csv -LiteralPath $extraGamesFile -Delimiter ';' -Encoding UTF8 | Where-Object { $_.Title -or $_.DownloadUrl })
    }
    if ($extraGames.Count -gt 0 -and $extraGames[0].PSObject.Properties.Name -notcontains 'Executable') {
        throw "Falta la columna Executable en $extraGamesFile. Usa el encabezado Title;DownloadUrl;Executable;Year."
    }
    foreach ($extraGame in $extraGames) {
        if ([string]::IsNullOrWhiteSpace($extraGame.Title) -or [string]::IsNullOrWhiteSpace($extraGame.DownloadUrl) -or [string]::IsNullOrWhiteSpace($extraGame.Executable)) {
            throw "Cada fila de $extraGamesFile debe tener Title, DownloadUrl y Executable. Year es opcional."
        }
    }
    $esdeZip = Get-Archive $Downloads[0].Name $Downloads[0].Url $Downloads[0].Archive
    $dosboxZip = Get-Archive $Downloads[1].Name $Downloads[1].Url $Downloads[1].Archive
    $gameZip = Get-Archive $Downloads[2].Name $Downloads[2].Url $Downloads[2].Archive
    $pinballZip = Get-Archive $Downloads[3].Name $Downloads[3].Url $Downloads[3].Archive
    $doomZip = Get-Archive $Downloads[4].Name $Downloads[4].Url $Downloads[4].Archive
    $popZip = Get-Archive $Downloads[5].Name $Downloads[5].Url $Downloads[5].Archive
    $hexxZip = Get-Archive $Downloads[6].Name $Downloads[6].Url $Downloads[6].Archive
    $omfZip = Get-Archive $Downloads[7].Name $Downloads[7].Url $Downloads[7].Archive
    $oldJazzCache = Join-Path $Cache 'extra-jazz-jackrabbit.zip'
    $newJazzCache = Join-Path $Cache $Downloads[8].Archive
    if (-not (Test-Path -LiteralPath $newJazzCache) -and (Test-Path -LiteralPath $oldJazzCache)) {
        Move-Item -LiteralPath $oldJazzCache -Destination $newJazzCache
        Write-Log 'Caché anterior de Jazz Jackrabbit renombrada para reflejar que ahora es un juego de la lista fija.'
    }
    $jazzZip = Get-Archive $Downloads[8].Name $Downloads[8].Url $Downloads[8].Archive
    $extraGamePackages = @()
    foreach ($extraGame in $extraGames) {
        $extraSlug = ConvertTo-SafeSlug $extraGame.Title
        $extraArchiveName = "extra-$extraSlug.zip"
        $extraArchive = Get-Archive "Juego adicional: $($extraGame.Title)" $extraGame.DownloadUrl $extraArchiveName
        $extraGameDir = Join-Path $Root "Games\Extras\$extraSlug"
        Expand-Once $extraArchive $extraGameDir '.ready-extra'
        $extraGamePackages += [pscustomobject]@{ Title=$extraGame.Title.Trim(); Slug=$extraSlug; Executable=$extraGame.Executable.Trim(); Year=([string]$extraGame.Year).Trim(); Directory=$extraGameDir }
    }

    $esdeDir = Join-Path $Root 'ES-DE'
    Expand-Once $esdeZip $esdeDir
    $dosboxDir = Join-Path $Root 'Emulators\dosbox-staging'
    Expand-Once $dosboxZip $dosboxDir
    $gameDir = Join-Path $Root 'Games\BreakMachine'
    Expand-Once $gameZip $gameDir '.ready-freeware-v14'
    $pinballDir = Join-Path $Root 'Games\ExtremePinball'
    Expand-Once $pinballZip $pinballDir '.ready-demo-v1'
    $pinballVideoConfig = Join-Path $pinballDir 'dosbox-video.conf'
    @('[render]', 'aspect = stretch', 'viewport = fit', 'integer_scaling = off') | Set-Content -LiteralPath $pinballVideoConfig -Encoding ASCII
    Write-Log 'Perfil de Extreme Pinball configurado para estirar la imagen a pantalla completa.'
    $doomDir = Join-Path $Root 'Games\DoomShareware'
    Expand-Once $doomZip $doomDir '.ready-shareware-v1'
    $popDir = Join-Path $Root 'Games\PrinceOfPersiaDemo'
    Expand-Once $popZip $popDir '.ready-playable-demo'
    $hexxDir = Join-Path $Root 'Games\Hexxagon'
    Expand-Once $hexxZip $hexxDir '.ready-shareware'
    $omfDir = Join-Path $Root 'Games\OneMustFall2097'
    Expand-Once $omfZip $omfDir '.ready-full-version'
    $jazzDir = Join-Path $Root 'Games\JazzJackrabbit'
    Expand-Once $jazzZip $jazzDir '.ready-shareware-v11'
    $jazzProgram = Get-ChildItem -LiteralPath $jazzDir -Filter 'JAZZ.EXE' -File -Recurse | Select-Object -First 1
    $jazzSetupProgram = Get-ChildItem -LiteralPath $jazzDir -Filter 'SETUP.EXE' -File -Recurse | Select-Object -First 1
    if (-not $jazzProgram -or -not $jazzSetupProgram) { throw 'El ZIP de Jazz Jackrabbit debe incluir JAZZ.EXE y SETUP.EXE.' }
    Write-Log 'Jazz Jackrabbit v1.1 extraído como juego de la lista fija del setup.'
    foreach ($extraGame in $extraGamePackages) {
        $declaredExecutable = ([string]$extraGame.Executable).Trim()
        if ([string]::IsNullOrWhiteSpace($declaredExecutable)) { throw "La fila de '$($extraGame.Title)' no indica el ejecutable. Añade la columna Executable a $extraGamesFile." }
        $declaredExecutable = $declaredExecutable.Replace('/', '\')
        if ([System.IO.Path]::IsPathRooted($declaredExecutable) -or $declaredExecutable -match '(^|\\)\.\.(\\|$)') {
            throw "Executable debe ser un nombre o una ruta relativa dentro del juego: '$declaredExecutable' para '$($extraGame.Title)'."
        }
        $program = $null
        if ($declaredExecutable.Contains('\')) {
            $candidatePath = Join-Path $extraGame.Directory $declaredExecutable
            $program = Get-Item -LiteralPath $candidatePath -ErrorAction SilentlyContinue
            if ($program -and $program.PSIsContainer) { $program = $null }
        } else {
            $programMatches = @(Get-ChildItem -LiteralPath $extraGame.Directory -Filter $declaredExecutable -File -Recurse)
            if ($programMatches.Count -gt 1) {
                throw "Hay varios archivos llamados '$declaredExecutable' en '$($extraGame.Title)'. Indica en Executable la ruta relativa completa dentro del ZIP."
            }
            if ($programMatches.Count -eq 1) { $program = $programMatches[0] }
        }
        if (-not $program) { throw "No se encontró el ejecutable indicado '$declaredExecutable' para '$($extraGame.Title)' en su ZIP." }
        $extraGame | Add-Member -NotePropertyName Program -NotePropertyValue $program -Force
        Write-Log "Ejecutable detectado para '$($extraGame.Title)': $($program.Name)"
    }

    $esdeExe = Get-ChildItem -LiteralPath $esdeDir -Filter 'ES-DE.exe' -File -Recurse | Select-Object -First 1
    if (-not $esdeExe) { throw 'No se encontró ES-DE.exe dentro del ZIP portable.' }
    $dosboxExe = Get-ChildItem -LiteralPath $dosboxDir -Filter 'dosbox.exe' -File -Recurse | Select-Object -First 1
    if (-not $dosboxExe) { $dosboxExe = Get-ChildItem -LiteralPath $dosboxDir -Filter 'dosbox-staging.exe' -File -Recurse | Select-Object -First 1 }
    if (-not $dosboxExe) { throw 'No se encontró el ejecutable DOSBox dentro del ZIP portable.' }
    $gameProgram = Get-ChildItem -LiteralPath $gameDir -Filter 'BRKMCH.BAT' -File -Recurse | Select-Object -First 1
    if (-not $gameProgram) { $gameProgram = Get-ChildItem -LiteralPath $gameDir -Filter 'BRKMCH.EXE' -File -Recurse | Select-Object -First 1 }
    if (-not $gameProgram) { $gameProgram = Get-ChildItem -LiteralPath $gameDir -Filter '*.BAT' -File -Recurse | Select-Object -First 1 }
    if (-not $gameProgram) { $gameProgram = Get-ChildItem -LiteralPath $gameDir -Filter '*.EXE' -File -Recurse | Select-Object -First 1 }
    if (-not $gameProgram) { throw 'No se encontró un archivo ejecutable BAT o EXE en el ZIP freeware.' }
    $pinballProgram = Get-ChildItem -LiteralPath $pinballDir -Filter 'PINBALL.EXE' -File -Recurse | Select-Object -First 1
    if (-not $pinballProgram) { $pinballProgram = Get-ChildItem -LiteralPath $pinballDir -Filter 'EXTREME.EXE' -File -Recurse | Select-Object -First 1 }
    if (-not $pinballProgram) { $pinballProgram = Get-ChildItem -LiteralPath $pinballDir -Filter 'XPINBALL.EXE' -File -Recurse | Select-Object -First 1 }
    if (-not $pinballProgram) { $pinballProgram = Get-ChildItem -LiteralPath $pinballDir -Filter '*.BAT' -File -Recurse | Select-Object -First 1 }
    if (-not $pinballProgram) { $pinballProgram = Get-ChildItem -LiteralPath $pinballDir -Filter '*.EXE' -File -Recurse | Select-Object -First 1 }
    if (-not $pinballProgram) { throw 'No se encontró un archivo ejecutable BAT o EXE en el ZIP de Extreme Pinball.' }
    $doomProgram = Get-ChildItem -LiteralPath $doomDir -Filter 'DOOM.EXE' -File -Recurse | Select-Object -First 1
    if (-not $doomProgram) { $doomProgram = Get-ChildItem -LiteralPath $doomDir -Filter '*.BAT' -File -Recurse | Select-Object -First 1 }
    if (-not $doomProgram) { $doomProgram = Get-ChildItem -LiteralPath $doomDir -Filter '*.EXE' -File -Recurse | Select-Object -First 1 }
    if (-not $doomProgram) { throw 'No se encontró DOOM.EXE ni otro lanzador BAT o EXE en el ZIP de DOOM.' }
    $popBootstrap = Get-ChildItem -LiteralPath $popDir -Filter 'POP1DEMO.EXE' -File -Recurse | Select-Object -First 1
    $popProgram = Get-ChildItem -LiteralPath $popDir -Filter 'PRINCE.EXE' -File -Recurse | Select-Object -First 1
    if (-not $popProgram -and -not $popBootstrap) { throw 'No se encontró PRINCE.EXE ni el desempaquetador pop1demo.exe de la demo de Prince of Persia.' }
    $hexxProgram = Get-ChildItem -LiteralPath $hexxDir -Filter 'HEXX.EXE' -File -Recurse | Select-Object -First 1
    if (-not $hexxProgram) { $hexxProgram = Get-ChildItem -LiteralPath $hexxDir -Filter '*.BAT' -File -Recurse | Select-Object -First 1 }
    if (-not $hexxProgram) { $hexxProgram = Get-ChildItem -LiteralPath $hexxDir -Filter '*.EXE' -File -Recurse | Select-Object -First 1 }
    if (-not $hexxProgram) { throw 'No se encontró HEXX.EXE ni otro lanzador BAT o EXE en el ZIP de Hexxagon.' }
    $omfInstaller = Get-ChildItem -LiteralPath $omfDir -Filter 'INSTALL.EXE' -File -Recurse | Select-Object -First 1
    if (-not $omfInstaller) { throw 'No se encontró INSTALL.EXE en el ZIP completo de One Must Fall 2097.' }

    # ES-DE Portable mantiene sus datos y sistemas junto a la aplicación.
    New-Item -ItemType File -Path (Join-Path $esdeExe.DirectoryName 'portable.txt') -Force | Out-Null
    $romDir = Join-Path $esdeExe.DirectoryName 'ROMs\windows'
    New-Item -ItemType Directory -Path $romDir -Force | Out-Null
    $launcher = Join-Path $romDir 'Break Machine (1995).bat'
    $dosboxRelative = Get-RelativePath $romDir $dosboxExe.FullName
    $gameRelative = Get-RelativePath $romDir $gameProgram.DirectoryName
    @(
        '@echo off',
        'setlocal',
        'set "LOG=%~dp0Break Machine launch.log"',
        'echo [%date% %time%] Starting Break Machine > "%LOG%"',
        ('set "DOSBOX=%~dp0{0}"' -f $dosboxRelative),
        ('set "GAMEDIR=%~dp0{0}"' -f $gameRelative),
        'if not exist "%DOSBOX%" (echo ERROR: DOSBox not found: "%DOSBOX%" >> "%LOG%" & exit /b 10)',
        ('if not exist "%GAMEDIR%\{0}" (echo ERROR: Game executable not found in "%GAMEDIR%" >> "%LOG%" & exit /b 11)' -f $gameProgram.Name),
        'echo DOSBox: "%DOSBOX%" >> "%LOG%"',
        'echo Game folder: "%GAMEDIR%" >> "%LOG%"',
        'pushd "%GAMEDIR%"',
        ('"%DOSBOX%" -noconsole --fullscreen -exit -c "mount c ." -c "c:" -c "{0}" >> "%LOG%" 2>&1' -f $gameProgram.Name),
        'set "DOSBOX_EXIT=%ERRORLEVEL%"',
        'popd',
        'echo DOSBox exit code: %DOSBOX_EXIT% >> "%LOG%"',
        'exit /b %DOSBOX_EXIT%'
    ) | Set-Content -LiteralPath $launcher -Encoding ASCII

    $pinballLauncher = Join-Path $romDir 'Extreme Pinball (1995).bat'
    $pinballGameRelative = Get-RelativePath $romDir $pinballProgram.DirectoryName
    @(
        '@echo off',
        'setlocal',
        'set "LOG=%~dp0Extreme Pinball launch.log"',
        'echo [%date% %time%] Starting Extreme Pinball demo > "%LOG%"',
        ('set "DOSBOX=%~dp0{0}"' -f $dosboxRelative),
        ('set "GAMEDIR=%~dp0{0}"' -f $pinballGameRelative),
        'if not exist "%DOSBOX%" (echo ERROR: DOSBox not found: "%DOSBOX%" >> "%LOG%" & exit /b 10)',
        ('if not exist "%GAMEDIR%\{0}" (echo ERROR: Game executable not found in "%GAMEDIR%" >> "%LOG%" & exit /b 11)' -f $pinballProgram.Name),
        'echo DOSBox: "%DOSBOX%" >> "%LOG%"',
        'echo Game folder: "%GAMEDIR%" >> "%LOG%"',
        'pushd "%GAMEDIR%"',
        ('"%DOSBOX%" --conf "%GAMEDIR%\dosbox-video.conf" -noconsole --fullscreen -exit -c "mount c ." -c "c:" -c "{0}" >> "%LOG%" 2>&1' -f $pinballProgram.Name),
        'set "DOSBOX_EXIT=%ERRORLEVEL%"',
        'popd',
        'echo DOSBox exit code: %DOSBOX_EXIT% >> "%LOG%"',
        'exit /b %DOSBOX_EXIT%'
    ) | Set-Content -LiteralPath $pinballLauncher -Encoding ASCII

    $doomLauncher = Join-Path $romDir 'DOOM (1993) (Shareware).bat'
    $doomGameRelative = Get-RelativePath $romDir $doomProgram.DirectoryName
    @(
        '@echo off',
        'setlocal',
        'set "LOG=%~dp0DOOM launch.log"',
        'echo [%date% %time%] Starting DOOM shareware > "%LOG%"',
        ('set "DOSBOX=%~dp0{0}"' -f $dosboxRelative),
        ('set "GAMEDIR=%~dp0{0}"' -f $doomGameRelative),
        'if not exist "%DOSBOX%" (echo ERROR: DOSBox not found: "%DOSBOX%" >> "%LOG%" & exit /b 10)',
        ('if not exist "%GAMEDIR%\{0}" (echo ERROR: Game executable not found in "%GAMEDIR%" >> "%LOG%" & exit /b 11)' -f $doomProgram.Name),
        'echo DOSBox: "%DOSBOX%" >> "%LOG%"',
        'echo Game folder: "%GAMEDIR%" >> "%LOG%"',
        'pushd "%GAMEDIR%"',
        ('"%DOSBOX%" -noconsole --fullscreen -exit -c "mount c ." -c "c:" -c "{0}" >> "%LOG%" 2>&1' -f $doomProgram.Name),
        'set "DOSBOX_EXIT=%ERRORLEVEL%"',
        'popd',
        'echo DOSBox exit code: %DOSBOX_EXIT% >> "%LOG%"',
        'exit /b %DOSBOX_EXIT%'
    ) | Set-Content -LiteralPath $doomLauncher -Encoding ASCII

    $jazzLauncher = Join-Path $romDir 'Jazz Jackrabbit (1994) (Shareware).bat'
    $jazzGameRelative = Get-RelativePath $romDir $jazzProgram.DirectoryName
    @(
        '@echo off',
        'setlocal',
        'set "LOG=%~dp0Jazz Jackrabbit launch.log"',
        'echo [%date% %time%] Starting Jazz Jackrabbit shareware > "%LOG%"',
        ('set "DOSBOX=%~dp0{0}"' -f $dosboxRelative),
        ('set "GAMEDIR=%~dp0{0}"' -f $jazzGameRelative),
        'if not exist "%DOSBOX%" (echo ERROR: DOSBox not found: "%DOSBOX%" >> "%LOG%" & exit /b 10)',
        'if not exist "%GAMEDIR%\JAZZ.EXE" (echo ERROR: JAZZ.EXE not found in "%GAMEDIR%" >> "%LOG%" & exit /b 11)',
        'if not exist "%GAMEDIR%\SOUNDCRD.INF" (',
        '  echo First run: configure and save the Jazz Jackrabbit sound settings.',
        '  echo Configuring Jazz Jackrabbit > "%LOG%"',
        '  pushd "%GAMEDIR%"',
        '  "%DOSBOX%" -noconsole --fullscreen -exit -c "mount c ." -c "c:" -c "SETUP.EXE" >> "%LOG%" 2>&1',
        '  set "SETUP_EXIT=%ERRORLEVEL%"',
        '  popd',
        '  if not exist "%GAMEDIR%\SOUNDCRD.INF" (echo ERROR: SETUP.EXE did not create SOUNDCRD.INF. Save the sound settings and exit setup. >> "%LOG%" & exit /b 12)',
        '  echo Jazz Jackrabbit sound configuration saved. >> "%LOG%"',
        ')',
        'echo DOSBox: "%DOSBOX%" >> "%LOG%"',
        'echo Game folder: "%GAMEDIR%" >> "%LOG%"',
        'pushd "%GAMEDIR%"',
        '"%DOSBOX%" -noconsole --fullscreen -exit -c "mount c ." -c "c:" -c "JAZZ.EXE" >> "%LOG%" 2>&1',
        'set "DOSBOX_EXIT=%ERRORLEVEL%"',
        'popd',
        'echo DOSBox exit code: %DOSBOX_EXIT% >> "%LOG%"',
        'exit /b %DOSBOX_EXIT%'
    ) | Set-Content -LiteralPath $jazzLauncher -Encoding ASCII

    $popLauncher = Join-Path $romDir 'Prince of Persia (1990) (Demo).bat'
    $popGameDirectory = if ($popProgram) { $popProgram.DirectoryName } else { $popBootstrap.DirectoryName }
    $popGameRelative = Get-RelativePath $romDir $popGameDirectory
    @(
        '@echo off',
        'setlocal',
        'set "LOG=%~dp0Prince of Persia demo launch.log"',
        'echo [%date% %time%] Starting Prince of Persia playable demo > "%LOG%"',
        ('set "DOSBOX=%~dp0{0}"' -f $dosboxRelative),
        ('set "GAMEDIR=%~dp0{0}"' -f $popGameRelative),
        'if not exist "%DOSBOX%" (echo ERROR: DOSBox not found: "%DOSBOX%" >> "%LOG%" & exit /b 10)',
        'if not exist "%GAMEDIR%\PRINCE.EXE" if not exist "%GAMEDIR%\pop1demo.exe" (echo ERROR: Prince of Persia game files and bootstrap are missing. >> "%LOG%" & exit /b 11)',
        'set "EXTRACT_COMMAND="',
        'if not exist "%GAMEDIR%\PRINCE.EXE" set "EXTRACT_COMMAND=-c pop1demo.exe"',
        'echo DOSBox: "%DOSBOX%" >> "%LOG%"',
        'echo Game folder: "%GAMEDIR%" >> "%LOG%"',
        'echo Extract command: %EXTRACT_COMMAND% >> "%LOG%"',
        'pushd "%GAMEDIR%"',
        '"%DOSBOX%" -noconsole --fullscreen -exit -c "mount c ." -c "c:" %EXTRACT_COMMAND% -c "PRINCE.EXE" >> "%LOG%" 2>&1',
        'set "DOSBOX_EXIT=%ERRORLEVEL%"',
        'popd',
        'echo DOSBox exit code: %DOSBOX_EXIT% >> "%LOG%"',
        'exit /b %DOSBOX_EXIT%'
    ) | Set-Content -LiteralPath $popLauncher -Encoding ASCII

    $hexxLauncher = Join-Path $romDir 'Hexxagon (1993).bat'
    $hexxGameRelative = Get-RelativePath $romDir $hexxProgram.DirectoryName
    @(
        '@echo off',
        'setlocal',
        'set "LOG=%~dp0Hexxagon launch.log"',
        'echo [%date% %time%] Starting Hexxagon shareware > "%LOG%"',
        ('set "DOSBOX=%~dp0{0}"' -f $dosboxRelative),
        ('set "GAMEDIR=%~dp0{0}"' -f $hexxGameRelative),
        'if not exist "%DOSBOX%" (echo ERROR: DOSBox not found: "%DOSBOX%" >> "%LOG%" & exit /b 10)',
        ('if not exist "%GAMEDIR%\{0}" (echo ERROR: Game executable not found in "%GAMEDIR%" >> "%LOG%" & exit /b 11)' -f $hexxProgram.Name),
        'echo DOSBox: "%DOSBOX%" >> "%LOG%"',
        'echo Game folder: "%GAMEDIR%" >> "%LOG%"',
        'pushd "%GAMEDIR%"',
        ('"%DOSBOX%" -noconsole --fullscreen -exit -c "mount c ." -c "c:" -c "{0}" >> "%LOG%" 2>&1' -f $hexxProgram.Name),
        'set "DOSBOX_EXIT=%ERRORLEVEL%"',
        'popd',
        'echo DOSBox exit code: %DOSBOX_EXIT% >> "%LOG%"',
        'exit /b %DOSBOX_EXIT%'
    ) | Set-Content -LiteralPath $hexxLauncher -Encoding ASCII

    $omfLauncher = Join-Path $romDir 'One Must Fall 2097 (1994).bat'
    $omfGameRelative = Get-RelativePath $romDir $omfDir
    @(
        '@echo off',
        'setlocal',
        'set "LOG=%~dp0One Must Fall 2097 launch.log"',
        'echo [%date% %time%] Starting One Must Fall 2097 > "%LOG%"',
        ('set "DOSBOX=%~dp0{0}"' -f $dosboxRelative),
        ('set "GAMEDIR=%~dp0{0}"' -f $omfGameRelative),
        'if not exist "%DOSBOX%" (echo ERROR: DOSBox not found: "%DOSBOX%" >> "%LOG%" & exit /b 10)',
        'if not exist "%GAMEDIR%\INSTALL.EXE" (echo ERROR: Installer not found in "%GAMEDIR%" >> "%LOG%" & exit /b 11)',
        'if not exist "%GAMEDIR%\OMF\OMF.EXE" (',
        '  echo First run: starting the DOS installer. Use its default C:\OMF destination. >> "%LOG%"',
        '  pushd "%GAMEDIR%"',
        '  "%DOSBOX%" -noconsole --fullscreen -exit -c "mount c ." -c "c:" -c "INSTALL.EXE" >> "%LOG%" 2>&1',
        '  set "INSTALL_EXIT=%ERRORLEVEL%"',
        '  popd',
        '  if not exist "%GAMEDIR%\OMF\OMF.EXE" (echo ERROR: Installer did not create OMF\OMF.EXE. Check the install log and rerun. >> "%LOG%" & exit /b 12)',
        ')',
        'pushd "%GAMEDIR%"',
        '"%DOSBOX%" -noconsole --fullscreen -exit -c "mount c ." -c "c:" -c "cd OMF" -c "OMF.EXE" >> "%LOG%" 2>&1',
        'set "DOSBOX_EXIT=%ERRORLEVEL%"',
        'popd',
        'echo DOSBox exit code: %DOSBOX_EXIT% >> "%LOG%"',
        'exit /b %DOSBOX_EXIT%'
    ) | Set-Content -LiteralPath $omfLauncher -Encoding ASCII

    foreach ($extraGame in $extraGamePackages) {
        $safeTitle = $extraGame.Title -replace '[<>:"/\\|?*]', '_'
        $extraLauncherName = "$safeTitle.bat"
        $extraLauncher = Join-Path $romDir $extraLauncherName
        $extraGameRelative = Get-RelativePath $romDir $extraGame.Directory
        $extraExecutableRelative = Get-RelativePath $extraGame.Directory $extraGame.Program.FullName
        # The archive is unpacked under Games\Extras\<slug>; launch exactly the
        # executable declared in extra_games.csv, preserving the ZIP's directory structure.
        $gameCheck = ('if not exist "%GAMEDIR%\{0}" (echo ERROR: Executable {0} from extra_games.csv not found in "%GAMEDIR%" >> "%LOG%" & exit /b 11)' -f $extraExecutableRelative)
        $gameCommand = ('"%DOSBOX%" -noconsole --fullscreen -exit -c "mount c ." -c "c:" -c "{0}" >> "%LOG%" 2>&1' -f $extraExecutableRelative)
        $extraLogName = "$safeTitle launch.log"
        $extraLauncherLines = @(
            '@echo off',
            'setlocal',
            ('set "LOG=%~dp0{0}"' -f $extraLogName),
            ('echo [%date% %time%] Starting {0} > "%LOG%"' -f $extraGame.Title),
            ('set "DOSBOX=%~dp0{0}"' -f $dosboxRelative),
            ('set "GAMEDIR=%~dp0{0}"' -f $extraGameRelative),
            ('echo CSV executable: {0} >> "%LOG%"' -f $extraExecutableRelative),
            'if not exist "%DOSBOX%" (echo ERROR: DOSBox not found: "%DOSBOX%" >> "%LOG%" & exit /b 10)'
        )
        $extraLauncherLines += @(
            $gameCheck,
            'echo DOSBox: "%DOSBOX%" >> "%LOG%"',
            'echo Game folder: "%GAMEDIR%" >> "%LOG%"',
            'pushd "%GAMEDIR%"',
            $gameCommand,
            'set "DOSBOX_EXIT=%ERRORLEVEL%"',
            'popd',
            'echo DOSBox exit code: %DOSBOX_EXIT% >> "%LOG%"',
            'exit /b %DOSBOX_EXIT%'
        )
        $extraLauncherLines | Set-Content -LiteralPath $extraLauncher -Encoding ASCII
        $extraGame | Add-Member -NotePropertyName Launcher -NotePropertyValue $extraLauncherName -Force
    }

    # Put release years in filenames and gamelist metadata to help scraper matching.
    $gameYearMetadata = @(
        [pscustomobject]@{ Old='Break Machine.bat'; File='Break Machine (1995).bat'; Name='Break Machine (1995)'; Date='19950101T000000' },
        [pscustomobject]@{ Old='Extreme Pinball.bat'; File='Extreme Pinball (1995).bat'; Name='Extreme Pinball (1995)'; Date='19950101T000000' },
        [pscustomobject]@{ Old='Jazz Jackrabbit.bat'; File='Jazz Jackrabbit (1994) (Shareware).bat'; Name='Jazz Jackrabbit (1994) (Shareware)'; Date='19940101T000000' },
        [pscustomobject]@{ Old='DOOM (Shareware).bat'; File='DOOM (1993) (Shareware).bat'; Name='DOOM (1993) (Shareware)'; Date='19931210T000000' },
        [pscustomobject]@{ Old='Prince of Persia (Demo).bat'; File='Prince of Persia (1990) (Demo).bat'; Name='Prince of Persia (1990) (Demo)'; Date='19900101T000000' },
        [pscustomobject]@{ Old='Hexxagon.bat'; File='Hexxagon (1993).bat'; Name='Hexxagon (1993)'; Date='19930101T000000' },
        [pscustomobject]@{ Old='One Must Fall 2097.bat'; File='One Must Fall 2097 (1994).bat'; Name='One Must Fall 2097 (1994)'; Date='19940101T000000' }
    )
    foreach ($extraGame in $extraGamePackages) {
        $extraFile = $extraGame.Launcher
        $extraDate = $null
        if ($extraGame.Year -match '^\d{4}$') { $extraDate = "$($extraGame.Year)0101T000000" }
        $displayTitle = $extraGame.Title
        if ($extraGame.Year -match '^\d{4}$' -and $displayTitle -notmatch "\($($extraGame.Year)\)") { $displayTitle = "$displayTitle ($($extraGame.Year))" }
        $gameYearMetadata += [pscustomobject]@{ Old=$extraFile; File=$extraFile; Name=$displayTitle; Date=$extraDate }
    }
    $gamelistDirectory = Join-Path $esdeExe.DirectoryName 'ES-DE\gamelists\windows'
    New-Item -ItemType Directory -Path $gamelistDirectory -Force | Out-Null
    $gamelistPath = Join-Path $gamelistDirectory 'gamelist.xml'
    if (Test-Path -LiteralPath $gamelistPath) {
        [xml]$gamelist = Get-Content -LiteralPath $gamelistPath -Raw -Encoding UTF8
    } else {
        [xml]$gamelist = '<gameList />'
    }
    foreach ($item in $gameYearMetadata) {
        $oldPath = './' + $item.Old
        $newPath = './' + $item.File
        $entry = $null
        foreach ($candidate in @($gamelist.gameList.game)) {
            if ($candidate.path -eq $oldPath -or $candidate.path -eq $newPath) { $entry = $candidate; break }
        }
        if (-not $entry) {
            $entry = $gamelist.CreateElement('game')
            $null = $gamelist.DocumentElement.AppendChild($entry)
        }
        $fields = @(@('path', $newPath), @('name', $item.Name))
        if ($item.Date) { $fields += ,@('releasedate', $item.Date) }
        foreach ($field in $fields) {
            $node = $entry.SelectSingleNode($field[0])
            if (-not $node) { $node = $gamelist.CreateElement($field[0]); $null = $entry.AppendChild($node) }
            $node.InnerText = $field[1]
        }
        $legacyLauncher = Join-Path $romDir $item.Old
        if ($item.Old -ne $item.File -and (Test-Path -LiteralPath $legacyLauncher)) { Remove-Item -LiteralPath $legacyLauncher -Force }
    }
    $gamelist.Save($gamelistPath)

    $shortcut = Join-Path $Root 'run-retro-portable.bat'
    @('@echo off', ('start "" "{0}" --debug' -f $esdeExe.FullName)) | Set-Content -LiteralPath $shortcut -Encoding ASCII
    Write-Log 'Configuración terminada. ES-DE mostrará los juegos configurados; el año se añadió al nombre y a los metadatos locales cuando se indicó en el CSV.'
    Write-Log ("Juegos adicionales del CSV configurados: {0}" -f $extraGamePackages.Count)
    Write-Log 'One Must Fall 2097 ejecutará su instalador DOS una sola vez al abrirse por primera vez; utiliza la ruta predeterminada C:\OMF.'
    Write-Log "Inicia ES-DE en modo de depuración desde: $shortcut"
    Write-Log "Registro detallado de ES-DE: $(Join-Path $esdeExe.DirectoryName 'logs\es_log.txt')"
    Write-Host "`nListo. Ejecuta 'run-retro-portable.bat' o abre ES-DE desde $($esdeExe.FullName)."
    Write-Host "Registro: $Log`nCaché reutilizable: $Cache"
}
catch {
    $errorDetail = $_.Exception.Message
    if ($_.InvocationInfo.ScriptLineNumber) { $errorDetail += " (línea $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line.Trim()))" }
    Write-Log $errorDetail 'ERROR'
    Write-Host "`nLa configuración no se completó. Vuelve a ejecutar el script: reutilizará los ZIP correctos de $Cache.`nRegistro: $Log" -ForegroundColor Red
    exit 1
}
