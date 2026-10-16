$ErrorActionPreference = 'Stop'

$root = "c:\Users\Adm\OneDrive - unb.br\Copilot\BEM_Axis"
$in = Join-Path $root "ocr_pdf_294_340_raw.txt"
$outFor = Join-Path $root "beacon_becker_ocr.for"
$outInc = Join-Path $root "beacon_common.inc"
$outSus = Join-Path $root "beacon_ocr_suspect_lines.txt"

$inc = @'
C-- COMMON BLOCK FOR BEACON
      COMMON A(400,401)
      COMMON U(400)
      COMMON X(100),Y(100)
      COMMON NORDER(100),NODE1(100),NODE2(100),NODE3(100)
      COMMON ISTORS(100),ISTORU(100),IDIREC(100)
      COMMON XTRAC(100,3),YTRAC(100,3),TTRAC(100,3),PTRAC(100,3)
      COMMON B11(100,3),B12(100,3),B21(100,3),B22(100,3)
      COMMON ANGNOR(100,3)
      COMMON PRESU(100,3),PRESXX(100,3),PRESYY(100,3),PRESXY(100,3)
      COMMON A11(200),A12(200),A21(200),A22(200)
      COMMON F11(200),F12(200),F21(200),F22(200)
      COMMON RHS1(200),RHS2(200),BN1(200),BN2(200)
      COMMON SIGXX(200),SIGXY(200),SIGYY(200),SIGZZ(200)
      COMMON SIG11(200),SIG12(200),SIG22(200),SIG33(200)
      COMMON NCHECK(200),DISPT(200),DISPN(200)
      COMMON XINT(200),YINT(200),SZZINT(200),UXINT(200),UYINT(200)
      COMMON SXXINT(200),SXYINT(200),SYYINT(200)
      COMMON XG(6),CG(6),XGL(6),CGL(6)
      COMMON GFACT(6),GSHAPF(6),GUXX(6),GUYX(6),GUXY(6)
      COMMON GUYY(6),GTXX(6),GTYX(6),GTXY(6),GTYY(6)
      COMMON CORDX(3),CORDY(3),SHAPF(3),ZETA(3),SHAPD(3)
      COMMON AA1(5),BB1(5),CC1(5),DD1(5)
      COMMON XTITL(80)
      COMMON PI,IGEOM,DMAX,E,XNU,XMU,NODEP,NODEQ,IELEMQ
      COMMON MAXELE,MAXNOD,MAXINT
      COMMON NELEMS,NEQN,NNODES,NGAUSS,NINPTS,NBCS,NBCU
      COMMON XP,XQ,YP,YQ,SCALEF,FN1,FN2,SI,XNORM,YNORM
      COMMON XJACOB,ILOG,ISELF
      COMMON UXX,UXY,UYX,UYY,TXX,TYX,TXY,TYY
      COMMON S1XX,S2XX,S1XY,S2XY,S1YX,S2YX,S1YY,S2YY
      COMMON D1XX,D2XX,D1XY,D2XY,D1YX,D2YX,D1YY,D2YY
      COMMON AM,ELLIPK,ELLIPE
      COMMON UXXE,UXXK,UXYE,UXYK,UYXE,UYXK,UYYE,UYYK
      COMMON TXXE,TXXK,TXYE,TXYK,TYXE,TYXK,TYYE,TYYK
      COMMON TE1,TE2,TE3,TE4,TE5,TE6,TE7,TE8
      COMMON TK1,TK2,TK3,TK4,TK5,TK6,TK7,TK8
      COMMON DUXXDR,DUXXDZ,DUXYDR,DUXYDZ,DUYXDR,DUYXDZ,DUYYDR,DUYYDZ
      COMMON DTXXDR,DTXXDZ,DTXYDR,DTXYDZ,DTYXDR,DTYXDZ,DTYYDR,DTYYDZ
'@
Set-Content -Path $outInc -Value $inc -Encoding ascii

$all = Get-Content -Path $in
$all = $all | ForEach-Object { $_ -replace [char]12, '' }

$progIdx = @()
for($i=0; $i -lt $all.Count; $i++){
  if($all[$i].Trim().ToUpper() -eq 'PROGRAM BEACON'){ $progIdx += $i }
}
if($progIdx.Count -lt 2){ throw "Could not find second PROGRAM BEACON" }
$start = $progIdx[1]

$diffIdx = -1
for($i=0; $i -lt $all.Count; $i++){
  if($all[$i].Trim().ToUpper() -eq 'SUBROUTINE DIFFAX'){ $diffIdx = $i; break }
}
if($diffIdx -lt 0){ throw "Could not find SUBROUTINE DIFFAX" }
$end = -1
for($i=$diffIdx; $i -lt $all.Count; $i++){
  if($all[$i].Trim().ToUpper() -eq 'END'){ $end = $i; break }
}
if($end -lt 0){ throw "Could not find END after DIFFAX" }

$code = $all[$start..$end]
$clean = New-Object System.Collections.Generic.List[string]

foreach($line in $code){
  $t = $line
  $t = $t -replace '•',''
  $t = $t -replace '™',''
  $t = $t -replace '—','-'
  $t = $t -replace '–','-'
  $trim = $t.Trim()

  if($trim -match '^FULL LISTING OF BEACON\s+\d+$'){ continue }
  if($trim -match '^THE BOUNDARY ELEMENT METHOD IN ENGINEERING$'){ continue }
  if($trim -match '^\d+$'){ continue }
  if($trim -match '^\*{8,}$'){ continue }
  if($trim -match '^C={4,}:?$'){ continue }
  if($trim -match '^C\s*[-=]{4,}:?$'){ continue }

  if($trim -match 'INSERT\s+COMMON\s+BLOCK'){
    $clean.Add("      INCLUDE 'beacon_common.inc'")
    continue
  }

  $clean.Add($t)
}

$normalized = New-Object System.Collections.Generic.List[string]
$prevInclude = $false
foreach($l in $clean){
  $isInclude = ($l.Trim().ToUpper() -eq "INCLUDE 'BEACON_COMMON.INC'")
  if($isInclude -and $prevInclude){ continue }
  $normalized.Add($l)
  $prevInclude = $isInclude
}

Set-Content -Path $outFor -Value $normalized -Encoding ascii

$sus = New-Object System.Collections.Generic.List[string]
$pat = '(\?|##|\bLAND\b|\bIELEMO\b|\bVQ\b|\bX0\b|\b1EE11\b|\bF0RMAT\b)'
for($i=0; $i -lt $normalized.Count; $i++){
  $ln = $normalized[$i]
  if($ln -match $pat){
    $sus.Add(("{0,5}: {1}" -f ($i+1), $ln))
  }
}
Set-Content -Path $outSus -Value $sus -Encoding ascii

Write-Host "WROTE: $outInc"
Write-Host "WROTE: $outFor"
Write-Host "WROTE: $outSus"
Get-Item $outInc,$outFor,$outSus | Select-Object Name,Length | Format-Table -AutoSize
