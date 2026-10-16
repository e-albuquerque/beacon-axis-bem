param(
    [string]$Exe = "",
    [string]$OutputDir = "results",
    [string]$ReferenceDir = "benchmarks/reference",
    [double]$AbsTol = 1e-4,
    [double]$RelTol = 1e-4,
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

function Compare-NumericTextFile {
    param(
        [string]$Actual,
        [string]$Expected,
        [string]$Label,
        [double]$AbsTol,
        [double]$RelTol
    )

    Require-File -Path $Actual
    Require-File -Path $Expected

    $numPattern = '[-+]?(?:\d+\.?\d*|\.\d+)(?:[EeDd][-+]?\d+)?'
    $actualLines = Get-Content -Path $Actual
    $expectedLines = Get-Content -Path $Expected

    if ($actualLines.Count -ne $expectedLines.Count) {
        Write-Host "FAIL: $Label"
        Write-Host "  line count differs: actual=$($actualLines.Count) expected=$($expectedLines.Count)"
        return $false
    }

    for ($i = 0; $i -lt $expectedLines.Count; $i++) {
        $expectedLine = $expectedLines[$i]
        $actualLine = $actualLines[$i]

        $expectedSkeleton = ([regex]::Replace($expectedLine, $numPattern, '<N>') -replace '\s+', ' ').Trim()
        $actualSkeleton = ([regex]::Replace($actualLine, $numPattern, '<N>') -replace '\s+', ' ').Trim()
        if ($expectedSkeleton -ne $actualSkeleton) {
            Write-Host "FAIL: $Label"
            Write-Host "  structure mismatch at line $($i + 1)"
            Write-Host "  actual  : $actualLine"
            Write-Host "  expected: $expectedLine"
            return $false
        }

        $expectedNums = [regex]::Matches($expectedLine, $numPattern)
        $actualNums = [regex]::Matches($actualLine, $numPattern)
        if ($expectedNums.Count -ne $actualNums.Count) {
            Write-Host "FAIL: $Label"
            Write-Host "  numeric token mismatch at line $($i + 1)"
            return $false
        }

        for ($j = 0; $j -lt $expectedNums.Count; $j++) {
            $expectedVal = [double]::Parse(($expectedNums[$j].Value -replace '[dD]', 'E'), [System.Globalization.CultureInfo]::InvariantCulture)
            $actualVal = [double]::Parse(($actualNums[$j].Value -replace '[dD]', 'E'), [System.Globalization.CultureInfo]::InvariantCulture)
            $diff = [Math]::Abs($actualVal - $expectedVal)
            $scale = [Math]::Max([Math]::Abs($actualVal), [Math]::Abs($expectedVal))
            $tol = $AbsTol + $RelTol * $scale
            if ($diff -gt $tol) {
                Write-Host "FAIL: $Label"
                Write-Host "  numeric mismatch at line $($i + 1), value $($j + 1):"
                Write-Host "  actual=$actualVal expected=$expectedVal diff=$diff tol=$tol"
                return $false
            }
        }
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
} else {
    & $runScript -Case sphere -Exe $Exe -OutputDir $OutputDir
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$actualSphereOut = Join-Path $root "$OutputDir/sphere.out"
$actualSphereErr = Join-Path $root "$OutputDir/sphere.err"

$expectedSphereOut = Join-Path $root "$ReferenceDir/sphere.out"
$expectedSphereErr = Join-Path $root "$ReferenceDir/sphere.err"

$ok = $true
$ok = (Compare-NumericTextFile -Actual $actualSphereOut -Expected $expectedSphereOut -Label "sphere.out" -AbsTol $AbsTol -RelTol $RelTol) -and $ok
$ok = (Compare-File -Actual $actualSphereErr -Expected $expectedSphereErr -Label "sphere.err") -and $ok

if (-not $ok) {
    throw "Benchmark comparison failed."
}

Write-Host "Benchmark suite passed."
