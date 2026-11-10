<#
.SYNOPSIS
  Compila el micrositio de autorelevo y lo despliega a App Engine. Ejecutar desde la raiz del repo del micrositio.
.EXAMPLE
  .\deploy.ps1
.EXAMPLE
  .\deploy.ps1 -Ambiente dev -Version autorelevo-prueba -NoPromote
#>
param(
  [ValidateSet('test', 'dev')][string]$Ambiente = 'test',
  [ValidatePattern('^[a-z0-9-]{1,63}$')][string]$Version,
  [switch]$NoPromote
)
$ErrorActionPreference = 'Stop'

# shortcut: los valores de dev no se han probado con este script; confirmar yaml y configuracion antes del primer uso.
$Ambientes = @{
  test = @{ Proyecto = 'morfeo-test';        Yaml = 'deploy\app.test.yaml'; Config = 'test';               Url = 'https://micrositio-autorelevo-web-dot-morfeo-test.ue.r.appspot.com' }
  dev  = @{ Proyecto = 'morfeo-dev-321917';  Yaml = 'deploy\app.dev.yaml';  Config = 'staging-autorelevo'; Url = 'https://micrositio-autorelevo-dot-morfeo-dev-321917.ue.r.appspot.com' }
}
$A = $Ambientes[$Ambiente]
$Log = Join-Path $PSScriptRoot "deploy-$($A.Proyecto)-autorelevo.log"

function Invoke-Paso([string]$Titulo, [scriptblock]$Accion) {
  Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Titulo" -ForegroundColor Cyan
  & $Accion
  if ($LASTEXITCODE) { throw "$Titulo fallo con codigo $LASTEXITCODE. Revisa el output de arriba." }
  Write-Host "[OK] $Titulo" -ForegroundColor Green
}

Start-Transcript -Path $Log -Append | Out-Null
try {
  Write-Host "Autorelevo - Deploy a $($A.Proyecto) | Config: $($A.Config) | Yaml: $($A.Yaml) | Log: $Log"
  if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) { throw 'gcloud no encontrado en PATH. Instala Google Cloud SDK.' }
  if (-not (Test-Path 'autorelevo\project.json')) { throw 'Ejecuta el script desde la raiz del repo del micrositio.' }
  if (-not (Test-Path $A.Yaml)) { throw "No existe $($A.Yaml)" }

  Invoke-Paso "[1/4] Build Angular ($($A.Config))" { npx.cmd nx build autorelevo "--configuration=$($A.Config)" --skip-nx-cache }

  $Origen = 'dist\autorelevo\browser'
  if (@(Get-ChildItem $Origen -Recurse -Filter '*.js' | Select-String -SimpleMatch 'morfeo-prod' -List).Count -gt 0) {
    throw 'El bundle contiene URLs de prod. Despliegue cancelado.'
  }

  Invoke-Paso '[2/4] Preparar deploy\dist' {
    if (Test-Path 'deploy\dist') { Remove-Item 'deploy\dist' -Recurse -Force }
    New-Item -ItemType Directory 'deploy\dist' | Out-Null
  }
  Invoke-Paso '[3/4] Copiar build' { Copy-Item "$Origen\*" 'deploy\dist' -Recurse }

  # shortcut: deploy\.env se agrega al final de env_variables (debe ser la ultima seccion del yaml); usar Secret Manager en test/prod.
  $YamlDeploy = $A.Yaml
  if (Test-Path 'deploy\.env') {
    $Extra = Get-Content 'deploy\.env' | Where-Object { $_ -match '^\s*[A-Z_][A-Z0-9_]*\s*=' } | ForEach-Object {
      $k, $v = $_ -split '=', 2
      '  {0}: "{1}"' -f $k.Trim(), ($v.Trim().Trim('"') -replace '"', '\"')
    }
    $Base = Get-Content $A.Yaml
    if (-not ($Base -match '^env_variables:')) { $Base += 'env_variables:' }
    $YamlDeploy = 'deploy\app.generated.yaml'
    $Base + $Extra | Set-Content $YamlDeploy -Encoding utf8
    Write-Host "Variables de deploy\.env agregadas: $(($Extra | ForEach-Object { ($_ -split ':')[0].Trim() }) -join ', ')"
  }

  $Argumentos = @('app', 'deploy', $YamlDeploy, "--project=$($A.Proyecto)", '--quiet')
  if ($Version) { $Argumentos += "--version=$Version" }
  if ($NoPromote) { $Argumentos += '--no-promote' }
  Invoke-Paso '[4/4] gcloud app deploy' { gcloud.cmd @Argumentos }

  Write-Host "`nDeploy completado. URL directa: $($A.Url)" -ForegroundColor Green
  if ($Ambiente -eq 'dev') { Write-Host 'URL via K2: https://dev.k2web.online/autorelevo (requiere dispatch.yaml desplegado en K2)' }
}
catch {
  Write-Host "ERROR: $_" -ForegroundColor Red
  exit 1
}
finally {
  if (Test-Path 'deploy\app.generated.yaml') { Remove-Item 'deploy\app.generated.yaml' -Force }
  Stop-Transcript | Out-Null
}
