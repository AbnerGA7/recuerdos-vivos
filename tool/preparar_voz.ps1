# Descarga el modelo de voz Kokoro (int8, español) y lo deja en assets\voz\kokoro.
# El modelo pesa unos 140 MB, por eso no va en el repositorio.
# Uso (desde la carpeta del proyecto):  powershell -ExecutionPolicy Bypass -File tool\preparar_voz.ps1
$ErrorActionPreference = 'Stop'

$url = 'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-int8-multi-lang-v1_0.tar.bz2'
$destino = Join-Path $PSScriptRoot '..\assets\voz\kokoro'
$tmp = Join-Path $env:TEMP ("kokoro-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

# Sumas SHA-256 esperadas de cada archivo.
$sumas = [ordered]@{
  'model.int8.onnx' = '75635ea3b85a32d00094dcdd61a258aba87c160f7c264c304a7b3ae9d734195e'
  'voices.bin'      = '1c5a5b983d3d50d8586d437a51f3faa2da7919ce76a013c081e65671a3447c29'
  'tokens.txt'      = '6ebb6bb288f20f3ae8d004d3c2ca27697da27c037d75e81a60e2a6a663f95425'
}

try {
  Write-Host 'Descargando el modelo de voz (unos 140 MB)...'
  $archivo = Join-Path $tmp 'modelo.tar.bz2'
  Invoke-WebRequest -Uri $url -OutFile $archivo
  # tar.exe viene con Windows 10 y 11 y entiende .tar.bz2.
  tar -xjf $archivo -C $tmp
  $origen = Join-Path $tmp 'kokoro-int8-multi-lang-v1_0'

  New-Item -ItemType Directory -Force -Path $destino | Out-Null
  foreach ($nombre in $sumas.Keys) {
    $ruta = Join-Path $origen $nombre
    $hash = (Get-FileHash -Path $ruta -Algorithm SHA256).Hash.ToLower()
    if ($hash -ne $sumas[$nombre]) { throw "La suma de $nombre no coincide. Vuelve a ejecutar el script." }
    Copy-Item -Path $ruta -Destination $destino -Force
  }
  Write-Host "Modelo de voz listo en $destino"
}
finally {
  Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
