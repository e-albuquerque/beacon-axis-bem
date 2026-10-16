$ErrorActionPreference = 'Stop'

$root = "c:\Users\Adm\OneDrive - unb.br\Copilot\BEM_Axis"
$in = Join-Path $root "beacon_becker_ocr.for"
$out = Join-Path $root "beacon_becker_clean.for"

$lines = Get-Content -Path $in
$outLines = New-Object System.Collections.Generic.List[string]

foreach($line in $lines){
  $t = $line

  if($t -match '^\s*\d+\s+THE BOUNDARY ELEMENT METHOD IN ENGINEERING\s*$'){ continue }
  if($t -match '^\s*FULL LISTING OF BEACON\s+\d+\s*$'){ continue }

  $t = $t -replace 'F0RMAT','FORMAT'
  $t = $t -replace '##','**'
  $t = $t -replace '\?\?','*'
  $t = $t -replace '\bLAND\b','1.AND.'
  $t = $t -replace 'IFd','IF('
  $t = $t -replace 'IELEMO','IELEMQ'
  $t = $t -replace 'NODEK\s+IELEMQ','NODE1 (IELEMQ'
  if($t.Trim() -eq 'EN'){ $t = 'THEN' }
  $t = $t -replace '\bVQ\b','YQ'
  $t = $t -replace 'ELLI\s+PE''','ELLIPE*'
  $t = $t -replace 'DKl\)R','DKDR'
  $t = $t -replace 'XN0RM','XNORM'
  $t = $t -replace 'DTI\s+DZ','DT1DZ'
  $t = $t -replace "'DCDZ",'*DCDZ'
  $t = $t -replace "'DDDZ",'*DDDZ'
  $t = $t -replace 'XC\*\*\?\?','XC**2'
  $t = $t -replace '\(\?\s*-','(2.0-'
  $t = $t -replace '\bCP\*XC\b','XP*XC'
  $t = $t -replace '1EE11','1PE11'
  $t = $t -replace '1\s+OX','10X'
  $t = $t -replace '\(lHX','(1HX'
  $t = $t -replace '111-','1H-'

  $t = $t -replace '\bAll\b','A11'
  $t = $t -replace '\bFll\b','F11'
  $t = $t -replace '\bBll\b','B11'
  $t = $t -replace '\bAl2\b','A12'
  $t = $t -replace '\bA2l\b','A21'
  $t = $t -replace '\bF2l\b','F21'
  $t = $t -replace '\bXNl\b','XN1'
  $t = $t -replace '\bFNl\b','FN1'
  $t = $t -replace '\bSUMCl\b','SUMC1'
  $t = $t -replace '\bSUMDl\b','SUMD1'
  $t = $t -replace '\bSl\b','S1'

  if($t.Trim() -eq 'DXDIUO.O'){ $t = 'DXDH=0.0' }

  $outLines.Add($t)
}

Set-Content -Path $out -Value $outLines -Encoding ascii

Write-Host "WROTE: $out"
(Get-Item $out) | Select-Object FullName,Length | Format-List
