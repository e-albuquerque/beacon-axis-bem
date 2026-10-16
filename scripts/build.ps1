param(
    [string]$Output = "",
    [switch]$Debug,
    [switch]$NoOptimize
)

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if ([string]::IsNullOrWhiteSpace($Output)) {
    if ($env:OS -eq "Windows_NT") {
        $Output = "bin/beacon.exe"
    } else {
        $Output = "bin/beacon"
    }
}

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

$flags = @("-std=legacy", "-Wall", "-fopenmp")
if ($Debug) {
    $flags += @("-g", "-fcheck=all", "-fbacktrace")
} elseif (-not $NoOptimize) {
    $flags += "-O2"
}

$srcFile = ""
$incDir = Join-Path $root "src"
$srcFile = Join-Path $root "src\beacon_modern.f90"
$flags += @("-ffree-form", "-ffree-line-length-none")
$linkFlags = @("-fopenmp", "-llapack", "-lblas")

if (-not (Test-Path $srcFile)) {
    throw "Source file not found: $srcFile"
}

Write-Host "Using compiler: $gfortran"
Write-Host "Output: $outputPath"
Write-Host "Source: $srcFile"

& $gfortran @flags $srcFile "-I$incDir" "-o" $outputPath @linkFlags
if ($LASTEXITCODE -ne 0) {
    throw "Build failed with exit code $LASTEXITCODE."
}

Write-Host "Build succeeded."
