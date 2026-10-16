$ErrorActionPreference = 'Stop'

$f = "c:\Users\Adm\OneDrive - unb.br\Copilot\BEM_Axis\beacon_becker_clean.for"
$txt = Get-Content $f -Raw

$txt = $txt -replace '\bIROWl\b','IROW1'
$txt = $txt -replace '\bICOLl\b','ICOL1'
$txt = $txt -replace '\bRHSl\b','RHS1'
$txt = $txt -replace 'B1KIELEM, IC\)','B11(IELEM, IC)'
$txt = $txt -replace 'IF\(D\.EQ\.', 'IF(ID.EQ.'
$txt = $txt -replace 'tfOW MAKE', 'C--NOW MAKE'
$txt = $txt -replace 'DCCUP THE POSITIONS', 'C--OCCUPY THE POSITIONS'

$txt = $txt -replace 'IF \( ISELF\. EQ\. \) UYY','IF(ISELF.EQ.0) UYY'
$txt = $txt -replace 'IF \( IS ELF \. EQ\. 1 \.AND\. ILOG-EQ\. \) UXX','IF(ISELF.EQ.1.AND.ILOG.EQ.0) UXX'
$txt = $txt -replace 'IF \( ISELF \. EQ \. 1 \. AND\. ILOG \. EQ\. \) UXY','IF(ISELF.EQ.1.AND.ILOG.EQ.0) UXY'

$txt = $txt -replace 'IF\(SELF\. EQ\.l\. AND\. ILOG\. EQ\.l\)','IF(ISELF.EQ.1.AND.ILOG.EQ.1)'
$txt = $txt -replace 'IF\(SELF\.EQ\. 1\.AND\.\. ILOG\. EQ\.l\)','IF(ISELF.EQ.1.AND.ILOG.EQ.1)'
$txt = $txt -replace 'IF\(SELF\. EQ\. 1\.AND\.\. ILOG\. EQ\.l\)','IF(ISELF.EQ.1.AND.ILOG.EQ.1)'

$txt = $txt -replace 'Xl=2 \.\s*\r?\n\*XP\* \*2\+XQ\*\*2\+2 \.\s*\r?\n\*ZZ','X1=2.*XP**2+XQ**2+2.*ZZ'
$txt = $txt -replace '\* \*2','**2'
$txt = $txt -replace "XC'XD",'XC*XD'
$txt = $txt -replace 'XC\* \*2','XC**2'
$txt = $txt -replace 'XX3 3','XX33'
$txt = $txt -replace 'DTEIDR','DTE1DR'
$txt = $txt -replace 'DTIDZ','DT1DZ'
$txt = $txt -replace '1\.AND\.\.', '1.AND.'

Set-Content -Path $f -Value $txt -Encoding ascii
Write-Host "patched $f"
