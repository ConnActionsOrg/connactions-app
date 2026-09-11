# Baixa os TTF estáticos de Epilogue (600, 700) e Plus Jakarta Sans (400, 600, 700) pela API de
# CSS do Google Fonts. Com user-agent de curl a API devolve TTF em vez de woff2. Licença OFL 1.1.
$ErrorActionPreference = 'Stop'
$destino = Join-Path (Split-Path $PSScriptRoot -Parent) 'assets\fontes'
New-Item -ItemType Directory -Force $destino | Out-Null

$familias = @{ 'Epilogue' = @(600, 700); 'Plus Jakarta Sans' = @(400, 600, 700) }
$nomes = @{ 400 = 'Regular'; 600 = 'SemiBold'; 700 = 'Bold' }

foreach ($familia in $familias.Keys) {
  $url = 'https://fonts.googleapis.com/css2?family=' + ($familia -replace ' ', '+') + ':wght@' + ($familias[$familia] -join ';')
  $css = (Invoke-WebRequest -Uri $url -UserAgent 'curl/8.0' -UseBasicParsing).Content
  foreach ($bloco in [regex]::Matches($css, '@font-face\s*\{[^}]*\}')) {
    $peso = [int][regex]::Match($bloco.Value, 'font-weight:\s*(\d+)').Groups[1].Value
    $origem = [regex]::Match($bloco.Value, 'url\(([^)]+\.ttf)\)').Groups[1].Value
    $arquivo = Join-Path $destino (($familia -replace ' ', '') + '-' + $nomes[$peso] + '.ttf')
    Invoke-WebRequest -Uri $origem -OutFile $arquivo -UseBasicParsing
    '{0,-32} {1,8:N0} bytes' -f (Split-Path -Leaf $arquivo), (Get-Item $arquivo).Length
  }
}
