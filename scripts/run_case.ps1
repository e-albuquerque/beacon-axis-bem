param(
    [ValidateSet("sphere")]
    [string]$Case = "sphere",
    [string]$Exe = "",
    [string]$OutputDir = "results",
    [switch]$Rebuild
)

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if ([string]::IsNullOrWhiteSpace($Exe)) {
    if ($env:OS -eq "Windows_NT") {
        $Exe = "bin/beacon.exe"
    } else {
        $Exe = "bin/beacon"
    }
}

$exePath = if ([System.IO.Path]::IsPathRooted($Exe)) { $Exe } else { Join-Path $root $Exe }
$altExePath = if ($exePath.EndsWith(".exe")) { $exePath.Substring(0, $exePath.Length - 4) } else { "$exePath.exe" }

if (Test-Path $exePath) {
    $resolvedExePath = $exePath
} elseif (Test-Path $altExePath) {
    $resolvedExePath = $altExePath
} else {
    $resolvedExePath = $null
}

if ($Rebuild -or -not $resolvedExePath) {
    & (Join-Path $PSScriptRoot "build.ps1") -Output $Exe
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed with exit code $LASTEXITCODE"
    }
}

if (Test-Path $exePath) {
    $resolvedExePath = $exePath
} elseif (Test-Path $altExePath) {
    $resolvedExePath = $altExePath
}
if (-not $resolvedExePath) {
    throw "Executable not found at: $exePath"
}
$exeFull = (Resolve-Path $resolvedExePath).Path

$dataFile = Join-Path $root "data\$Case.dat"
if (-not (Test-Path $dataFile)) {
    throw "Input file not found: $dataFile"
}

$outDir = if ([System.IO.Path]::IsPathRooted($OutputDir)) { $OutputDir } else { Join-Path $root $OutputDir }
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$workDir = Join-Path $root ".work"
if (Test-Path $workDir) {
    Remove-Item $workDir -Recurse -Force
}
New-Item -ItemType Directory -Path $workDir | Out-Null

Copy-Item $dataFile (Join-Path $workDir "fort.7") -Force

Push-Location $workDir
try {
    & $exeFull > "$Case.out" 2> "$Case.err"
    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

Move-Item (Join-Path $workDir "$Case.out") (Join-Path $outDir "$Case.out") -Force
Move-Item (Join-Path $workDir "$Case.err") (Join-Path $outDir "$Case.err") -Force
Remove-Item $workDir -Recurse -Force

if ($exitCode -ne 0) {
    throw "Execution failed for case '$Case' with exit code $exitCode. See $OutputDir\\$Case.err"
}

Write-Host "Run completed: $Case"
Write-Host "Output: $OutputDir\\$Case.out"
Write-Host "Errors: $OutputDir\\$Case.err"
