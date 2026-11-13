<#
.SYNOPSIS
  Compila el micrositio de autorelevo y lo despliega a App Engine. server.js lee los secretos de Secret Manager al arrancar; deploy\.env no se usa.
  Ejecutar desde la raiz del repo del micrositio.
.EXAMPLE
  .\deploy-w-secrets-micrositio.ps1 -Ambiente dev -Version sin-env
.EXAMPLE
  .\deploy-w-secrets-micrositio.ps1 -Ambiente dev -Version autorelevo -Promote
#>
param(
  [ValidateSet('test', 'dev')][string]$Ambiente = 'dev',
  [ValidatePattern('^[a-z0-9-]{1,63}$')][string]$Version,
  [switch]$Promote
)
$ErrorActionPreference = 'Stop'

$Servicio = 'micrositio-autorelevo-web'
$Secretos = 'k2-portal-email', 'k2-portal-password', 'avasa-api-key'
$Ambientes = @{
  test = @{ Proyecto = 'morfeo-test';       Yaml = 'deploy\app.test.yaml'; Config = 'test';               Host = 'morfeo-test.ue.r.appspot.com' }
  dev  = @{ Proyecto = 'morfeo-dev-321917'; Yaml = 'deploy\app.dev.yaml';  Config = 'staging-autorelevo'; Host = 'morfeo-dev-321917.ue.r.appspot.com' }
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
  Write-Host "Autorelevo - Deploy a $($A.Proyecto) | Version: $Version | Promote: $Promote | Log: $Log"
  if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) { throw 'gcloud no encontrado en PATH. Instala Google Cloud SDK.' }
  if (-not (Test-Path 'autorelevo\project.json')) { throw 'Ejecuta el script desde la raiz del repo del micrositio.' }
  if (-not (Test-Path $A.Yaml)) { throw "No existe $($A.Yaml)" }
  if (Select-String -Path $A.Yaml -Pattern 'AVASA_API_KEY|K2_PORTAL_(EMAIL|PASSWORD)' -Quiet) {
    throw "$($A.Yaml) trae credenciales en env_variables; quitalas para que server.js use Secret Manager."
  }
  # server.js carga deploy\.env si llega a App Engine y tendria prioridad sobre Secret Manager.
  if ((Test-Path 'deploy\.env') -and (Select-String -Path 'deploy\.env' -Pattern '^\s*(AVASA_API_KEY|K2_PORTAL_EMAIL|K2_PORTAL_PASSWORD)\s*=' -Quiet)) {
    throw 'deploy\.env tiene credenciales sin comentar; comentalas con # para que server.js use Secret Manager.'
  }

  # Solo valida que existan y no esten vacios; el valor nunca se imprime.
  foreach ($s in $Secretos) {
    $Largo = (gcloud.cmd secrets versions access latest "--secret=$s" "--project=$($A.Proyecto)" 2>$null | Out-String).Trim().Length
    if ($LASTEXITCODE -or -not $Largo) { throw "No se pudo leer '$s' en Secret Manager de $($A.Proyecto) o esta vacio." }
    Write-Host "[OK] Secreto $s ($Largo caracteres)" -ForegroundColor Green
  }

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

  $Trafico = if ($Promote) { '--promote' } else { '--no-promote' }
  $Argumentos = @('app', 'deploy', $A.Yaml, "--project=$($A.Proyecto)", $Trafico, '--quiet')
  if ($Version) { $Argumentos += "--version=$Version" }
  Invoke-Paso '[4/4] gcloud app deploy' { gcloud.cmd @Argumentos }

  $UrlServicio = "https://$Servicio-dot-$($A.Host)"
  if ($Promote) {
    Write-Host "`nDeploy completado y promovido: $UrlServicio" -ForegroundColor Green
  } else {
    $V = if ($Version) { $Version } else {
      (gcloud.cmd app versions list "--service=$Servicio" "--project=$($A.Proyecto)" --sort-by=~version.createTime --limit=1 --format='value(id)' | Out-String).Trim()
    }
    $Sub = "$V-dot-$Servicio-dot-$($A.Proyecto)"
    Write-Host "`nDeploy completado SIN trafico. $UrlServicio sigue sirviendo la version anterior." -ForegroundColor Yellow
    # Arriba de 63 caracteres el certificado *.appspot.com no cubre la URL de version.
    if ($Sub.Length -gt 63) { Write-Host "La URL de la version no sirve por HTTPS ($($Sub.Length) > 63 caracteres); para probarla hay que promoverla." -ForegroundColor Yellow }
    else { Write-Host "Version: https://$Sub.ue.r.appspot.com" }
    Write-Host "Promover: gcloud app services set-traffic $Servicio --splits=$V=1 --project=$($A.Proyecto)"
  }
}
catch {
  Write-Host "ERROR: $_" -ForegroundColor Red
  exit 1
}
finally {
  Stop-Transcript | Out-Null
}
