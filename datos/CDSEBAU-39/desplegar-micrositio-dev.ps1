<#
.SYNOPSIS
  Compila el micrositio y lo despliega a App Engine en morfeo-dev. Ejecutar desde la raiz del repo Micrositio-Autorelevo.
.EXAMPLE
  .\desplegar-micrositio-dev.ps1 -Version autorelevo-prueba
.EXAMPLE
  .\desplegar-micrositio-dev.ps1 -Version micrositio-autorelevo -Promote
#>
param(
  [Parameter(Mandatory)][ValidatePattern('^[a-z0-9-]{1,63}$')][string]$Version,
  [ValidateSet('staging', 'staging-autorelevo')][string]$Configuracion = 'staging-autorelevo',
  [string]$Yaml = 'deploy/app.dev.yaml',
  # shortcut: ruta supuesta porque deploy/ no se ha revisado; ajustarla a lo que sirve deploy/server.js.
  [string]$DistDestino = 'deploy/dist/autorelevo',
  [switch]$Promote
)
$ErrorActionPreference = 'Stop'
$Proyecto = 'morfeo-dev-321917'

function Invoke-Paso([string]$Exe, [string[]]$Argumentos) {
  & $Exe @Argumentos
  if ($LASTEXITCODE -ne 0) { throw "Fallo: $Exe $($Argumentos -join ' ')" }
}

if (-not (Test-Path 'autorelevo/project.json')) { throw 'Ejecuta el script desde la raiz del repo.' }
if (-not (Test-Path $Yaml)) { throw "No existe $Yaml" }
$DeployDir = Split-Path $Yaml -Parent
if ((Resolve-Path $DeployDir).Path -notlike "$((Get-Location).Path)*") { throw 'El yaml debe estar dentro del repo.' }

Invoke-Paso 'npx.cmd' @('nx', 'build', 'autorelevo', "--configuration=$Configuracion")

$Origen = 'dist/autorelevo'
$Bundles = Get-ChildItem $Origen -Recurse -Filter '*.js'
if (-not $Bundles) { throw "No hay .js en $Origen" }
if ($Bundles | Select-String -SimpleMatch -Quiet -Pattern 'morfeo-prod', 'morfeo-test') {
  throw 'El bundle contiene URLs de prod o test. Despliegue cancelado.'
}
if (-not ($Bundles | Select-String -SimpleMatch -Quiet -Pattern $Proyecto)) {
  throw "El bundle no apunta a $Proyecto. Despliegue cancelado."
}

if (Test-Path $DistDestino) { Remove-Item $DistDestino -Recurse -Force }
New-Item -ItemType Directory -Force -Path $DistDestino | Out-Null
Copy-Item "$Origen/*" $DistDestino -Recurse

$Trafico = if ($Promote) { '--promote' } else { '--no-promote' }
Write-Host "Proyecto: $Proyecto | Yaml: $Yaml | Version: $Version | Trafico: $Trafico"
if ((Read-Host 'Escribe DESPLEGAR para continuar') -cne 'DESPLEGAR') { throw 'Cancelado por el usuario.' }

Invoke-Paso 'gcloud.cmd' @('app', 'deploy', $Yaml, "--project=$Proyecto", "--version=$Version", $Trafico, '--quiet')
Write-Host 'Despliegue terminado. Verifica en Network que el login vaya a morfeo-dev.'
