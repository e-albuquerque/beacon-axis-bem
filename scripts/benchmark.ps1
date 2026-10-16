param(
    [string]$Exe = "bin/beacon.exe",
    [string]$OutputDir = "results",
    [string]$ReferenceDir = "benchmarks/reference",
    [switch]$Rebuild
)

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Require-File {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Required file not found: $Path"
    }
}

function Compare-File {
    param(
        [string]$Actual,
        [string]$Expected,
        [string]$Label
    )

    Require-File -Path $Actual
    Require-File -Path $Expected

    $actualHash = (Get-FileHash -Algorithm SHA256 -Path $Actual).Hash
    $expectedHash = (Get-FileHash -Algorithm SHA256 -Path $Expected).Hash

    if ($actualHash -ne $expectedHash) {
        Write-Host "FAIL: $Label"
        Write-Host "  actual  : $Actual"
        Write-Host "  expected: $Expected"
        return $false
    }

    Write-Host "PASS: $Label"
    return $true
}

$runScript = Join-Path $PSScriptRoot "run_case.ps1"
Require-File -Path $runScript

# Build once when requested (run_case will skip build if exe exists)
if ($Rebuild) {
    & $runScript -Case sphere -Exe $Exe -OutputDir $OutputDir -Rebuild
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $runScript -Case cylinder -Exe $Exe -OutputDir $OutputDir
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    & $runScript -Case sphere -Exe $Exe -OutputDir $OutputDir
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $runScript -Case cylinder -Exe $Exe -OutputDir $OutputDir
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$actualSphereOut = Join-Path $root "$OutputDir/sphere.out"
$actualSphereErr = Join-Path $root "$OutputDir/sphere.err"
$actualCylinderOut = Join-Path $root "$OutputDir/cylinder.out"
$actualCylinderErr = Join-Path $root "$OutputDir/cylinder.err"

$expectedSphereOut = Join-Path $root "$ReferenceDir/sphere.out"
$expectedSphereErr = Join-Path $root "$ReferenceDir/sphere.err"
$expectedCylinderOut = Join-Path $root "$ReferenceDir/cylinder.out"
$expectedCylinderErr = Join-Path $root "$ReferenceDir/cylinder.err"

$ok = $true
$ok = (Compare-File -Actual $actualSphereOut -Expected $expectedSphereOut -Label "sphere.out") -and $ok
$ok = (Compare-File -Actual $actualSphereErr -Expected $expectedSphereErr -Label "sphere.err") -and $ok
$ok = (Compare-File -Actual $actualCylinderOut -Expected $expectedCylinderOut -Label "cylinder.out") -and $ok
$ok = (Compare-File -Actual $actualCylinderErr -Expected $expectedCylinderErr -Label "cylinder.err") -and $ok

if (-not $ok) {
    throw "Benchmark comparison failed."
}

Write-Host "Benchmark suite passed."
