<#
  Configura una instalación portable de ES-DE + DOSBox Staging + Break Machine.
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
    [pscustomobject]@{ Name='Break Machine freeware v1.4'; Url='https://d1.xp.myabandonware.com/t/554209a9-71a5-4c7a-af20-1fe33afece8d/Break-Machine_DOS_EN_v14-Freeware.zip'; Archive='break-machine-freeware-v14.zip' }
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

try {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    New-Item -ItemType Directory -Path $Cache -Force | Out-Null
    Write-Log 'Inicio de configuración.'
    $esdeZip = Get-Archive $Downloads[0].Name $Downloads[0].Url $Downloads[0].Archive
    $dosboxZip = Get-Archive $Downloads[1].Name $Downloads[1].Url $Downloads[1].Archive
    $gameZip = Get-Archive $Downloads[2].Name $Downloads[2].Url $Downloads[2].Archive

    $esdeDir = Join-Path $Root 'ES-DE'
    Expand-Once $esdeZip $esdeDir
    $dosboxDir = Join-Path $Root 'Emulators\dosbox-staging'
    Expand-Once $dosboxZip $dosboxDir
    $gameDir = Join-Path $Root 'Games\BreakMachine'
    Expand-Once $gameZip $gameDir '.ready-freeware-v14'

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

    # ES-DE Portable mantiene sus datos y sistemas junto a la aplicación.
    New-Item -ItemType File -Path (Join-Path $esdeExe.DirectoryName 'portable.txt') -Force | Out-Null
    $romDir = Join-Path $esdeExe.DirectoryName 'ROMs\windows'
    New-Item -ItemType Directory -Path $romDir -Force | Out-Null
    $launcher = Join-Path $romDir 'Break Machine.bat'
    $rootPrefix = $Root.TrimEnd('\') + '\'
    $dosboxRelative = '..\..\' + $dosboxExe.FullName.Substring($rootPrefix.Length).Replace('/', '\')
    $gameRelative = '..\..\' + $gameProgram.DirectoryName.Substring($rootPrefix.Length).Replace('/', '\')
    @(
        '@echo off',
        'setlocal',
        ('set "DOSBOX=%~dp0{0}"' -f $dosboxRelative),
        ('set "GAMEDIR=%~dp0{0}"' -f $gameRelative),
        'pushd "%GAMEDIR%"',
        ('"%DOSBOX%" -noconsole -exit -c "mount c ." -c "c:" -c "{0}"' -f $gameProgram.Name),
        'popd'
    ) | Set-Content -LiteralPath $launcher -Encoding ASCII

    $shortcut = Join-Path $Root 'Jugar Break Machine.bat'
    @('@echo off', ('start "" "{0}"' -f $esdeExe.FullName)) | Set-Content -LiteralPath $shortcut -Encoding ASCII
    Write-Log 'Configuración terminada. ES-DE mostrará Break Machine en el sistema Windows.'
    Write-Log "Inicia el juego desde: $shortcut"
    Write-Host "`nListo. Ejecuta 'Jugar Break Machine.bat' o abre ES-DE desde $($esdeExe.FullName)."
    Write-Host "Registro: $Log`nCaché reutilizable: $Cache"
}
catch {
    Write-Log $_.Exception.Message 'ERROR'
    Write-Host "`nLa configuración no se completó. Vuelve a ejecutar el script: reutilizará los ZIP correctos de $Cache.`nRegistro: $Log" -ForegroundColor Red
    exit 1
}
