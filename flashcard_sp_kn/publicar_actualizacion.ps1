

$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURACION
# ============================================================


# Carpeta del proyecto Flutter
$ProjectRoot = $PSScriptRoot

# Carpeta del servidor:
# 1. Usa FLASHCARD_SERVER_DIR si está configurada.
# 2. En caso contrario, busca el servidor junto al proyecto Flutter.
$ServerDir = $env:FLASHCARD_SERVER_DIR

if ([string]::IsNullOrWhiteSpace($ServerDir)) {
    $ServerDir = Join-Path $ProjectRoot "..\flashcard-update-server"
}

$ServerDir = [System.IO.Path]::GetFullPath($ServerDir)


# Carpetas del servidor
$ReleasesDir = Join-Path $ServerDir "releases"
$ManifestPath = Join-Path $ReleasesDir "manifest.json"

# APK
$ApkName = "flashcard-sp-kn.apk"
$ApkSource = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-release.apk"
$ApkDestination = Join-Path $ReleasesDir $ApkName




Write-Host ""
Write-Host "=========================================="
Write-Host "  FLASHCARD SP-KN - PUBLICAR ACTUALIZACION"
Write-Host "=========================================="
Write-Host ""

# ============================================================
# 1. COMPROBAR ARCHIVOS Y HERRAMIENTAS
# ============================================================

$PubspecPath = Join-Path $ProjectRoot "pubspec.yaml"

if (-not (Test-Path $PubspecPath)) {
    throw "No se encontro pubspec.yaml en $ProjectRoot"
}

if (-not (Test-Path $ManifestPath)) {
    throw "No se encontro el manifiesto: $ManifestPath"
}

if (-not (Test-Path $ReleasesDir)) {
    throw "No existe la carpeta de publicaciones: $ReleasesDir"
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter no esta disponible en el PATH."
}

# ============================================================
# 3. LEER VERSION DESDE PUBSPEC.YAML
# ============================================================

$PubspecContent = Get-Content $PubspecPath -Raw

$VersionMatch = [regex]::Match(
    $PubspecContent,
    '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$'
)

if (-not $VersionMatch.Success) {
    throw "No se pudo leer la version. Usa el formato: version: 1.0.1+2"
}

$Version = $VersionMatch.Groups[1].Value
$BuildNumber = [int]$VersionMatch.Groups[2].Value

Write-Host "Version: $Version"
Write-Host "Compilacion: $BuildNumber"

# ============================================================
# 4. LEER MANIFIESTO EXISTENTE
# ============================================================

$Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

if ([int]$Manifest.build_number -ge $BuildNumber) {
    throw "La compilacion del pubspec.yaml debe ser mayor que la del servidor ($($Manifest.build_number))."
}

if ([string]::IsNullOrWhiteSpace([string]$Manifest.apk_url)) {
    throw "apk_url no esta configurada en manifest.json."
}
if ([string]$Manifest.apk_url -notmatch '^https://') {
    throw "La URL de distribucion del APK debe usar HTTPS para una compilacion release."
}

# Mantener la URL existente.
$ApkUrl = [string]$Manifest.apk_url

# Conservar las notas de la version anterior.
if ($Manifest.release_notes) {
    $ReleaseNotes = @($Manifest.release_notes)
}
else {
    $ReleaseNotes = @("Actualizacion de FlashCard SP-KN.")
}

# ============================================================
# 5. INSTALAR DEPENDENCIAS Y COMPILAR
# ============================================================

Write-Host ""
Write-Host "Instalando dependencias..." -ForegroundColor Yellow

Push-Location $ProjectRoot

try {
    flutter pub get

    if ($LASTEXITCODE -ne 0) {
        throw "flutter pub get fallo."
    }

    Write-Host ""
    Write-Host "Compilando APK release..." -ForegroundColor Yellow

    $FlutterArgs = @(
        "build",
        "apk",
        "--release"
    )

    & flutter @FlutterArgs

    if ($LASTEXITCODE -ne 0) {
        throw "La compilacion del APK fallo."
    }
}
finally {
    Pop-Location
}

if (-not (Test-Path $ApkSource)) {
    throw "Flutter no genero el APK esperado: $ApkSource"
}

# ============================================================
# 6. COPIAR APK AL SERVIDOR
# ============================================================

Write-Host ""
Write-Host "Copiando APK al servidor..." -ForegroundColor Yellow

Copy-Item $ApkSource $ApkDestination -Force

# ============================================================
# 7. CALCULAR SHA-256
# ============================================================

$Sha256 = (Get-FileHash `
    -Path $ApkDestination `
    -Algorithm SHA256).Hash.ToLowerInvariant()

Write-Host "SHA-256: $Sha256"

# ============================================================
# 8. ACTUALIZAR MANIFIESTO
# ============================================================

$NewManifest = [ordered]@{
    version       = $Version
    build_number  = $BuildNumber
    release_notes = @($ReleaseNotes)
    apk_url       = $ApkUrl
    sha256        = $Sha256
}

$Json = $NewManifest | ConvertTo-Json -Depth 10
$TempManifest = "$ManifestPath.tmp"

[System.IO.File]::WriteAllText(
    $TempManifest,
    $Json + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
)

Move-Item $TempManifest $ManifestPath -Force

# ============================================================
# 9. RESUMEN
# ============================================================

Write-Host ""
Write-Host "=========================================="
Write-Host "  PUBLICACION COMPLETADA"
Write-Host "=========================================="
Write-Host "Version:    $Version"
Write-Host "Build:      $BuildNumber"
Write-Host "APK:        $ApkDestination"
Write-Host "Manifiesto: $ManifestPath"
Write-Host "URL APK:    $ApkUrl"
Write-Host ""
Write-Host "SHA-256:    $Sha256"
Write-Host ""
Write-Host "Verifica el manifiesto desde tu navegador:"
Write-Host ($ApkUrl -replace '/[^/]+$', '/manifest.json')
Write-Host ""
