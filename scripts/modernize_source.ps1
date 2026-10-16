$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Split-CommonVars {
    param([string]$text)
    $vars = New-Object System.Collections.Generic.List[string]
    $cur = ''
    $depth = 0

    foreach($ch in $text.ToCharArray()) {
        if($ch -eq '(') {
            $depth++
            $cur += $ch
            continue
        }
        if($ch -eq ')') {
            $depth--
            $cur += $ch
            continue
        }
        if($ch -eq ',' -and $depth -eq 0) {
            $tok = $cur.Trim()
            if($tok) { [void]$vars.Add($tok) }
            $cur = ''
            continue
        }
        $cur += $ch
    }

    $tok = $cur.Trim()
    if($tok) { [void]$vars.Add($tok) }
    return $vars
}

function Normalize-CodeOutsideQuotes {
    param([string]$line)

    $segments = New-Object System.Collections.Generic.List[object]
    $buf = New-Object System.Text.StringBuilder
    $inString = $false

    for($i = 0; $i -lt $line.Length; $i++) {
        $ch = $line[$i]

        if($ch -eq "'") {
            if($inString) {
                [void]$buf.Append($ch)
                if($i + 1 -lt $line.Length -and $line[$i + 1] -eq "'") {
                    [void]$buf.Append("'")
                    $i++
                } else {
                    $segments.Add([pscustomobject]@{ IsString = $true; Text = $buf.ToString() })
                    $buf.Clear() | Out-Null
                    $inString = $false
                }
            } else {
                if($buf.Length -gt 0) {
                    $segments.Add([pscustomobject]@{ IsString = $false; Text = $buf.ToString() })
                    $buf.Clear() | Out-Null
                }
                [void]$buf.Append($ch)
                $inString = $true
            }
            continue
        }

        [void]$buf.Append($ch)
    }

    if($buf.Length -gt 0) {
        $segments.Add([pscustomobject]@{ IsString = $inString; Text = $buf.ToString() })
    }

    $result = New-Object System.Text.StringBuilder
    foreach($seg in $segments) {
        if($seg.IsString) {
            [void]$result.Append($seg.Text)
            continue
        }

        $text = $seg.Text
        $text = $text -replace "`t", " "
        $text = [regex]::Replace($text, '\s+', ' ')
        $text = [regex]::Replace($text, '\s*\.\s*', '.')
        $text = [regex]::Replace($text, '\s*([()=,*+/\-])\s*', '$1')
        [void]$result.Append($text)
    }

    return $result.ToString().Trim()
}

# Build module declarations from legacy common block include.
$incPath = 'src\beacon_common.inc'
$incLines = Get-Content $incPath
$decls = [ordered]@{}

foreach($ln in $incLines) {
    if($ln -match '^\s*COMMON\s+(.+)$') {
        $rhs = $Matches[1].Trim()
        $vars = Split-CommonVars -text $rhs
        foreach($v in $vars) {
            if($v -match '^([A-Za-z][A-Za-z0-9_]*)\s*\(([^\)]+)\)$') {
                $name = $Matches[1].ToLower()
                $dims = $Matches[2].Trim()
                $decls[$name] = "($dims)"
            } elseif($v -match '^([A-Za-z][A-Za-z0-9_]*)$') {
                $name = $Matches[1].ToLower()
                if(-not $decls.Contains($name)) {
                    $decls[$name] = $null
                }
            }
        }
    }
}

$ints = New-Object System.Collections.Generic.List[string]
$reals = New-Object System.Collections.Generic.List[string]
$chars = New-Object System.Collections.Generic.List[string]

foreach($name in $decls.Keys) {
    $dim = $decls[$name]
    $entry = if($dim) { "$name$dim" } else { $name }

    if($name -eq 'xtitl') {
        [void]$chars.Add($entry)
        continue
    }

    $first = $name.Substring(0,1)
    if($first -match '[i-n]') {
        [void]$ints.Add($entry)
    } else {
        [void]$reals.Add($entry)
    }
}

$moduleLines = New-Object System.Collections.Generic.List[string]
[void]$moduleLines.Add('module beacon_state')
[void]$moduleLines.Add('  implicit none')
[void]$moduleLines.Add('')
if($ints.Count -gt 0) {
    [void]$moduleLines.Add('  integer :: ' + ($ints -join ', '))
    [void]$moduleLines.Add('')
}
if($reals.Count -gt 0) {
    [void]$moduleLines.Add('  real :: ' + ($reals -join ', '))
    [void]$moduleLines.Add('')
}
if($chars.Count -gt 0) {
    [void]$moduleLines.Add('  character(len=1) :: ' + ($chars -join ', '))
}
[void]$moduleLines.Add('end module beacon_state')
[void]$moduleLines.Add('')

# Convert fixed-form source into free-form statements.
$legacyPath = 'src\beacon_becker.for'
$rawLines = Get-Content $legacyPath
$stmtLines = New-Object System.Collections.Generic.List[string]
$current = $null

function Flush-Current {
    if($script:current -ne $null) {
        [void]$script:stmtLines.Add($script:current.TrimEnd())
        $script:current = $null
    }
}

foreach($line in $rawLines) {
    if([string]::IsNullOrWhiteSpace($line)) {
        Flush-Current
        [void]$stmtLines.Add('')
        continue
    }

    $firstChar = $line.Substring(0,1)
    if($firstChar -eq 'C' -or $firstChar -eq 'c' -or $firstChar -eq '*') {
        Flush-Current
        $comment = if($line.Length -gt 1) { $line.Substring(1).TrimEnd() } else { '' }
        [void]$stmtLines.Add('!' + $comment)
        continue
    }

    $padded = $line.PadRight(6)
    $labelField = $padded.Substring(0,5)
    $contField = $padded.Substring(5,1)
    $code = if($line.Length -gt 6) { $line.Substring(6) } else { '' }

    $isCont = ($contField -ne ' ' -and $contField -ne '0')
    if(-not $isCont) {
        Flush-Current
        $label = $labelField.Trim()
        $stmt = $code.TrimEnd()
        if($label -match '^\d+$') {
            $current = "$label $stmt"
        } else {
            $current = $stmt
        }
    } else {
        if($current -eq $null) {
            $current = ''
        }
        $current = ($current + ' ' + $code.Trim()).TrimEnd()
    }
}
Flush-Current

# Final cleanup + include replacement.
$converted = New-Object System.Collections.Generic.List[string]
foreach($ln in $stmtLines) {
    if($ln -match "^\s*INCLUDE\s*'beacon_common\.inc'\s*$" -or
       $ln -match '^\s*include\s*''beacon_common\.inc''\s*$') {
        [void]$converted.Add('  use beacon_state')
        continue
    }

    if($ln.StartsWith('!') -or [string]::IsNullOrWhiteSpace($ln)) {
        [void]$converted.Add($ln)
        continue
    }

    $work = $ln
    $label = ''
    if($work -match '^\s*(\d+)\s+(.+)$') {
        $label = $Matches[1]
        $work = $Matches[2]
    }

    $work = Normalize-CodeOutsideQuotes -line $work
    if($label) {
        [void]$converted.Add("$label $work")
    } else {
        [void]$converted.Add($work)
    }
}

$outPath = 'src\beacon_modern.f90'
Set-Content -Path $outPath -Value ($moduleLines + $converted) -Encoding ascii
Write-Host "Generated modern source: $outPath"
