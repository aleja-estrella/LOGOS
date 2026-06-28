# =============================================
#   LOGOS - Organizador y lanzador
#   Clic derecho -> Ejecutar con PowerShell
# =============================================

$carpeta = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "  ✝  LOGOS - La Palabra Viva" -ForegroundColor Yellow
Write-Host "  Buscando y organizando archivos..." -ForegroundColor Gray
Write-Host ""

# Buscar los archivos en Descargas y subcarpetas
$descargas = [Environment]::GetFolderPath('UserProfile') + '\Downloads'

function BuscarArchivo($nombre) {
    $resultado = Get-ChildItem -Path $descargas -Recurse -Filter $nombre -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $resultado) {
        $resultado = Get-ChildItem -Path $carpeta -Recurse -Filter $nombre -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    return $resultado
}

# Buscar cada archivo
Write-Host "  Buscando logos.html..." -ForegroundColor Gray
$fLogos = BuscarArchivo "logos.html"

Write-Host "  Buscando biblia_en.json (Espanol)..." -ForegroundColor Gray
$fES = BuscarArchivo "biblia_en.json"

Write-Host "  Buscando en_kjv.json (Ingles)..." -ForegroundColor Gray
$fEN = BuscarArchivo "en_kjv.json"

Write-Host ""

# Mover/copiar todos a la carpeta de este script
$errores = $false

if ($fLogos) {
    Copy-Item $fLogos.FullName "$carpeta\logos.html" -Force
    Write-Host "  ✅ logos.html encontrado y copiado" -ForegroundColor Green
} else {
    Write-Host "  ❌ logos.html NO encontrado" -ForegroundColor Red
    $errores = $true
}

if ($fES) {
    Copy-Item $fES.FullName "$carpeta\biblia_en.json" -Force
    Write-Host "  ✅ biblia_en.json encontrado y copiado" -ForegroundColor Green
} else {
    Write-Host "  ❌ biblia_en.json NO encontrado" -ForegroundColor Red
    $errores = $true
}

if ($fEN) {
    Copy-Item $fEN.FullName "$carpeta\en_kjv.json" -Force
    Write-Host "  ✅ en_kjv.json encontrado y copiado" -ForegroundColor Green
} else {
    Write-Host "  ❌ en_kjv.json NO encontrado" -ForegroundColor Red
    $errores = $true
}

if ($errores) {
    Write-Host ""
    Write-Host "  Algunos archivos no se encontraron." -ForegroundColor Red
    Write-Host "  Copia manualmente estos archivos a la misma carpeta que este .ps1:" -ForegroundColor Yellow
    Write-Host "    - logos.html" -ForegroundColor White
    Write-Host "    - biblia_en.json" -ForegroundColor White
    Write-Host "    - en_kjv.json" -ForegroundColor White
    Write-Host ""
    Read-Host "  Presiona Enter para cerrar"
    exit
}

Write-Host ""
Write-Host "  Todos los archivos listos. Iniciando app..." -ForegroundColor Cyan
Write-Host ""

# Leer los 3 archivos
Write-Host "  Cargando Biblia Espanol RVR..." -ForegroundColor Gray
$bES = Get-Content "$carpeta\biblia_en.json" -Raw -Encoding UTF8

Write-Host "  Cargando Biblia Ingles KJV..." -ForegroundColor Gray
$bEN = Get-Content "$carpeta\en_kjv.json" -Raw -Encoding UTF8

Write-Host "  Preparando aplicacion..." -ForegroundColor Gray
$html = Get-Content "$carpeta\logos.html" -Raw -Encoding UTF8

# Inyectar los JSON dentro del HTML para que funcione sin servidor
$inject = "<script>window.__BES__=$bES;window.__BEN__=$bEN;</script>"
$html = $html -replace '</head>', "$inject</head>"

# Parchear loadBibles para usar datos inyectados
$patchedFn = 'async function loadBibles(){try{bES=window.__BES__||null;if(!bES){const r=await fetch(FILE_ES);if(!r.ok)throw new Error();bES=await r.json();}}catch{document.getElementById(''splash'').innerHTML=''<div style="text-align:center;padding:28px;color:#c8bca8"><div style="font-size:22px;color:#d4a853;margin-bottom:12px">Error cargando Biblia</div></div>'';return;}try{bEN=window.__BEN__||null;if(!bEN){const r=await fetch(FILE_EN);if(r.ok)bEN=await r.json();}}catch{}setTimeout(()=>{document.getElementById(''splash'').classList.add(''hide'');setTimeout(()=>{renderBooks();showVOD();},500);},1800);}'

$html = $html -replace 'async function loadBibles\(\)\{[^}]+\{[^}]+\}[^}]+\}[^}]+\}[^}]+\}', $patchedFn

# Guardar temporal y abrir
$tmp = "$env:TEMP\logos_app_$(Get-Random).html"
[System.IO.File]::WriteAllText($tmp, $html, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "  ✅ Abriendo LOGOS en tu navegador..." -ForegroundColor Green
Write-Host "  Puedes cerrar esta ventana" -ForegroundColor Gray
Write-Host ""

Start-Process $tmp
Start-Sleep -Seconds 2
