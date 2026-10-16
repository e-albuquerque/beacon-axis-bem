param(
    [string]$Output = "bin/beacon.exe",
    [ValidateSet("modern", "legacy")]
    [string]$Flavor = "modern",
    [switch]$Debug,
    [switch]$NoOptimize
)

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$compilerCandidates = @()
$cmd = Get-Command gfortran -ErrorAction SilentlyContinue
if ($cmd) {
    $compilerCandidates += $cmd.Source
}
$compilerCandidates += "C:\msys64\ucrt64\bin\gfortran.exe"
$compilerCandidates += "C:\msys64\mingw64\bin\gfortran.exe"

$gfortran = $compilerCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $gfortran) {
    throw "gfortran not found. Install MSYS2 UCRT64 or add gfortran to PATH."
}

$outputPath = Join-Path $root $Output
$outDir = Split-Path -Parent $outputPath
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$flags = @("-std=legacy", "-Wall")
if ($Debug) {
    $flags += @("-g", "-fcheck=all", "-fbacktrace")
} elseif (-not $NoOptimize) {
    $flags += "-O2"
}

$srcFile = ""
$incDir = Join-Path $root "src"

if ($Flavor -eq "modern") {
    $srcFile = Join-Path $root "src\beacon_modern.f90"
    $flags += @("-ffree-form", "-ffree-line-length-none")
} else {
    $srcFile = Join-Path $root "src\beacon_becker.for"
    $flags += @("-ffixed-form", "-ffixed-line-length-none")
}

if (-not (Test-Path $srcFile)) {
    throw "Source file not found: $srcFile"
}

Write-Host "Using compiler: $gfortran"
Write-Host "Output: $outputPath"
Write-Host "Flavor: $Flavor"
Write-Host "Source: $srcFile"

& $gfortran @flags $srcFile "-I$incDir" "-o" $outputPath
if ($LASTEXITCODE -ne 0) {
    throw "Build failed with exit code $LASTEXITCODE."
}

Write-Host "Build succeeded."
