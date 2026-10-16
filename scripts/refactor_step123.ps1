$ErrorActionPreference = 'Stop'
try { $PSNativeCommandUseErrorActionPreference = $false } catch {}

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$srcPath = Join-Path $root 'src\beacon_modern.f90'
if (-not (Test-Path $srcPath)) {
    throw "Source not found: $srcPath"
}

$compiler = Get-Command gfortran -ErrorAction SilentlyContinue
if ($compiler) {
    $compilerPath = $compiler.Source
} elseif (Test-Path 'C:\msys64\ucrt64\bin\gfortran.exe') {
    $compilerPath = 'C:\msys64\ucrt64\bin\gfortran.exe'
} elseif (Test-Path 'C:\msys64\mingw64\bin\gfortran.exe') {
    $compilerPath = 'C:\msys64\mingw64\bin\gfortran.exe'
} else {
    throw 'gfortran not found.'
}

$lines = Get-Content $srcPath

# Map procedures and line ranges.
$procedures = @()
$inProc = $false
$procStart = 0
$procName = ''

for ($i = 0; $i -lt $lines.Count; $i++) {
    $ln = $lines[$i]
    if (-not $inProc) {
        if ($ln -match '^\s*(PROGRAM|SUBROUTINE)\s+([A-Za-z][A-Za-z0-9_]*)\b') {
            $inProc = $true
            $procStart = $i + 1
            $procName = $Matches[2].ToUpper()
        }
    } else {
        if ($ln -match '^\s*END\s*$') {
            $procedures += [pscustomobject]@{
                Name  = $procName
                Start = $procStart
                End   = $i + 1
            }
            $inProc = $false
            $procStart = 0
            $procName = ''
        }
    }
}

function Get-ProcedureForLine {
    param(
        [int]$lineNum,
        [object[]]$procList
    )
    foreach ($p in $procList) {
        if ($lineNum -ge $p.Start -and $lineNum -le $p.End) {
            return $p
        }
    }
    return $null
}

# Step 1: collect undeclared symbol diagnostics from -fimplicit-none.
$oldPref = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$diag = & $compilerPath -ffree-form -ffree-line-length-none -std=legacy -fimplicit-none -c $srcPath 2>&1 |
    ForEach-Object { $_.ToString() }
$ErrorActionPreference = $oldPref

$currentLine = $null
$procSymbols = @{}

foreach ($d in $diag) {
    if ($d -match 'src\\beacon_modern\.f90:(\d+):\d+:') {
        $currentLine = [int]$Matches[1]
        continue
    }

    if ($d -match "Error: Symbol '([A-Za-z][A-Za-z0-9_]*)' at") {
        if ($null -eq $currentLine) { continue }

        $sym = $Matches[1].ToLower()
        $proc = Get-ProcedureForLine -lineNum $currentLine -procList $procedures
        if ($null -eq $proc) { continue }

        if (-not $procSymbols.ContainsKey($proc.Name)) {
            $procSymbols[$proc.Name] = New-Object 'System.Collections.Generic.HashSet[string]'
        }
        [void]$procSymbols[$proc.Name].Add($sym)
    }
}

# Build insertion plan: implicit none + local declarations.
$insertMap = @{}
foreach ($p in $procedures) {
    $insertAfter = $p.Start

    for ($ln = $p.Start + 1; $ln -le [Math]::Min($p.End, $p.Start + 8); $ln++) {
        if ($lines[$ln - 1] -match '^\s*use\s+beacon_state\b') {
            $insertAfter = $ln
            break
        }
    }

    $nextLine = if ($insertAfter + 1 -le $lines.Count) { $lines[$insertAfter] } else { '' }
    $declLines = New-Object System.Collections.Generic.List[string]
    if ($nextLine -match '^\s*implicit\s+none\b') {
        $insertAfter = $insertAfter + 1
    } else {
        $declLines.Add('  implicit none') | Out-Null
    }

    if ($procSymbols.ContainsKey($p.Name)) {
        $intVars = New-Object System.Collections.Generic.List[string]
        $realVars = New-Object System.Collections.Generic.List[string]

        foreach ($s in ($procSymbols[$p.Name] | Sort-Object)) {
            $c = $s.Substring(0, 1)
            if ($c -match '[i-n]') {
                $intVars.Add($s) | Out-Null
            } else {
                $realVars.Add($s) | Out-Null
            }
        }

        if ($intVars.Count -gt 0) {
            $declLines.Add('  integer :: ' + ($intVars -join ', ')) | Out-Null
        }
        if ($realVars.Count -gt 0) {
            $declLines.Add('  real :: ' + ($realVars -join ', ')) | Out-Null
        }
    }

    if ($declLines.Count -gt 0) {
        $insertMap[$insertAfter] = $declLines
    }
}

# Apply insertion plan.
$out = New-Object System.Collections.Generic.List[string]
for ($ln = 1; $ln -le $lines.Count; $ln++) {
    $out.Add($lines[$ln - 1]) | Out-Null
    if ($insertMap.ContainsKey($ln)) {
        foreach ($add in $insertMap[$ln]) {
            $out.Add($add) | Out-Null
        }
    }
}

# Step 2: convert labeled DO loops to END DO.
$converted = New-Object System.Collections.Generic.List[string]
$loopEndCounts = @{}

foreach ($ln in $out) {
    if ($ln -match '^\s*DO\s+(\d+)\s+(.+)$') {
        $lbl = $Matches[1]
        $rest = $Matches[2]
        if (-not $loopEndCounts.ContainsKey($lbl)) { $loopEndCounts[$lbl] = 0 }
        $loopEndCounts[$lbl] = [int]$loopEndCounts[$lbl] + 1
        $converted.Add('DO ' + $rest) | Out-Null
        continue
    }

    if ($ln -match '^\s*(\d+)\s+CONTINUE\s*$') {
        $lbl = $Matches[1]
        if ($loopEndCounts.ContainsKey($lbl) -and [int]$loopEndCounts[$lbl] -gt 0) {
            $n = [int]$loopEndCounts[$lbl]
            $converted.Add($lbl + ' END DO') | Out-Null
            $n--
            while ($n -gt 0) {
                $converted.Add('END DO') | Out-Null
                $n--
            }
            $loopEndCounts[$lbl] = 0
            continue
        }
    }

    $converted.Add($ln) | Out-Null
}

# Step 3: targeted warning cleanup.
for ($k = 0; $k -lt $converted.Count; $k++) {
    if ($converted[$k] -match '^\s*SUBROUTINE\s+SINGU2\b') {
        for ($m = $k; $m -lt [Math]::Min($converted.Count, $k + 120); $m++) {
            if ($converted[$m] -match '^\s*DO\s+IG=1,NGAUSS\s*$') {
                if ($converted[$m - 1] -notmatch '^\s*COEFF\s*=') {
                    $converted.Insert($m, 'COEFF=0.0')
                    $converted.Insert($m, 'ISUBEL=1')
                }
                break
            }
        }
    }

    if ($converted[$k] -match '^\s*SUBROUTINE\s+ANGLES\b') {
        for ($m = $k; $m -lt [Math]::Min($converted.Count, $k + 160); $m++) {
            if ($converted[$m] -match '^\s*THETA\s*=') {
                if ($converted[$m + 1] -notmatch '^\s*ANG\s*=') {
                    $converted.Insert($m + 1, 'ANG=0.0')
                }
                break
            }
        }
    }

    if ($converted[$k] -match '^\s*SUBROUTINE\s+ASSEMB\b') {
        for ($m = $k; $m -lt [Math]::Min($converted.Count, $k + 160); $m++) {
            if ($converted[$m] -match '^\s*DO\s+NODEP=1,NNODES\s*$') {
                if ($converted[$m + 1] -notmatch '^\s*RELXP\s*=') {
                    $converted.Insert($m + 1, 'RELXP=0.0')
                }
                break
            }
        }
    }
}

Set-Content -Path $srcPath -Value $converted -Encoding ascii
Write-Host 'Step 1/2/3 refactor applied to src/beacon_modern.f90'
