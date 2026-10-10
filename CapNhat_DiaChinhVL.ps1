# ============================================================
#  CapNhat_DiaChinhVL.ps1 - Cap nhat DiaChinhVL tu GitHub
#  Thay NGUYEN FILE DiaChinhVL.mvba (khong sua code trong MicroStation
#  -> khong bi treo, khong can VBA IDE). Chay bang CapNhat_DiaChinhVL.bat
# ============================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Raw  = 'https://raw.githubusercontent.com/lehoangtuat/DiaChinhVL/main'
$Dest = 'C:\DiaChinhVL'
$Ini  = Join-Path $Dest 'DiaChinhVL.ini'
$MsMvba = Join-Path $env:ProgramData 'Bentley\MicroStation V8i (SELECTseries)\WorkSpace\projects\untitled\vba\DiaChinhVL.mvba'

function Thoat($code) { Write-Host ''; Read-Host 'Bam Enter de dong' | Out-Null; exit $code }
function SoPB($s) { $p = ($s.Trim() -split '\.') + @('0','0','0'); return [int]$p[0]*1000000 + [int]$p[1]*1000 + [int]$p[2] }
function Tai($url, $out) {
    $u = "$url`?t=$([DateTime]::Now.Ticks)"
    for ($i = 1; $i -le 3; $i++) {
        try {
            if ($out) { Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $out -TimeoutSec 120; return $true }
            else { return (Invoke-WebRequest -UseBasicParsing -Uri $u -TimeoutSec 30).Content }
        } catch { Start-Sleep -Seconds 2 }
    }
    if ($out) { return $false } else { return '' }
}

Write-Host '============================================================'
Write-Host '  CAP NHAT DIA CHINH VL'
Write-Host '============================================================'

# ---------- Phien ban ----------
$cu = '1.0'
if (Test-Path $Ini) {
    $l = Get-Content $Ini -Encoding UTF8 | Where-Object { $_ -match '^\s*PHIENBAN\s*=' } | Select-Object -First 1
    if ($l) { $cu = ($l -split '=', 2)[1].Trim() }
}
$v = Tai "$Raw/version.txt" $null
if (-not $v) { Write-Host '  [LOI] Khong ket noi duoc GitHub. Kiem tra mang Internet.' -ForegroundColor Red; Thoat 1 }
$dong = ($v -replace "`r", '') -split "`n"
$moi = $dong[0].Trim()
Write-Host "  Dang dung : $cu"
Write-Host "  Ban moi   : $moi"
$dong | Select-Object -Skip 1 | Where-Object { $_.Trim() } | ForEach-Object { Write-Host "    $_" }
if ((SoPB $moi) -le (SoPB $cu)) {
    Write-Host ''
    Write-Host '  Ban dang dung la ban moi nhat.' -ForegroundColor Green
    $r = Read-Host '  Van muon cai lai? (C/K)'
    if ($r -notmatch '^[cCyY]') { Thoat 0 }
}

# ---------- Tai file moi ----------
Write-Host ''
Write-Host '  Dang tai DiaChinhVL.mvba ...'
$tmp = Join-Path $env:TEMP 'DiaChinhVL_moi.mvba'
if (-not (Tai "$Raw/DiaChinhVL.mvba" $tmp)) { Write-Host '  [LOI] Khong tai duoc DiaChinhVL.mvba.' -ForegroundColor Red; Thoat 1 }
$b = [IO.File]::ReadAllBytes($tmp)
if ($b.Length -lt 200000 -or $b[0] -ne 0xD0 -or $b[1] -ne 0xCF -or $b[2] -ne 0x11 -or $b[3] -ne 0xE0) {
    Write-Host '  [LOI] File tai ve bi hong. Thu lai sau.' -ForegroundColor Red; Thoat 1
}
Write-Host "  [OK] Da tai ($([math]::Round($b.Length/1KB)) KB)" -ForegroundColor Green

# ---------- Tu dong MicroStation (ban ve da auto save) ----------
$MoLaiFile = Join-Path $Dest 'capnhat_molai.txt'
$exe = $null
$ps = @(Get-Process ustation -ErrorAction SilentlyContinue)
if ($ps.Count -gt 0) {
    try { $exe = $ps[0].Path } catch {}
    Write-Host ''
    Write-Host '  Dang dong MicroStation de cap nhat ...' -ForegroundColor Yellow
    foreach ($p in $ps) { try { [void]$p.CloseMainWindow() } catch {} }
    $t0 = Get-Date
    while ((Get-Process ustation -ErrorAction SilentlyContinue) -and ((Get-Date) - $t0).TotalSeconds -lt 15) { Start-Sleep -Milliseconds 500 }
    if (Get-Process ustation -ErrorAction SilentlyContinue) {
        Stop-Process -Name ustation -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    Write-Host '  MicroStation da dong.' -ForegroundColor Green
    Start-Sleep -Seconds 1
}
if (-not $exe) {
    foreach ($c in @("${env:ProgramFiles(x86)}\Bentley\MicroStation V8i (SELECTseries)\MicroStation\ustation.exe",
                     "$env:ProgramFiles\Bentley\MicroStation V8i (SELECTseries)\MicroStation\ustation.exe")) {
        if (Test-Path $c) { $exe = $c; break }
    }
}

# ---------- Thay file ----------
$dich = @((Join-Path $Dest 'DiaChinhVL.mvba'))
if (Test-Path $MsMvba) { $dich += $MsMvba }
$loi = 0
foreach ($d in $dich) {
    try {
        if (Test-Path $d) { Copy-Item $d "$d.bak" -Force }
        Copy-Item $tmp $d -Force
        Write-Host "  [OK] $d" -ForegroundColor Green
    } catch {
        $loi++
        Write-Host "  [LOI] $d : $($_.Exception.Message)" -ForegroundColor Red
    }
}
Remove-Item $tmp -ErrorAction SilentlyContinue
if ($loi -gt 0) { Write-Host '  Chay lai bang quyen Administrator (chuot phai -> Run as administrator).' -ForegroundColor Yellow; Thoat 1 }

# ---------- Ghi phien ban ----------
$lines = @()
if (Test-Path $Ini) { $lines = @(Get-Content $Ini -Encoding UTF8 | Where-Object { $_ -notmatch '^\s*PHIENBAN\s*=' }) }
$lines += "PHIENBAN=$moi"
$utf8 = New-Object Text.UTF8Encoding($true)
[IO.File]::WriteAllLines($Ini, [string[]]$lines, $utf8)

Write-Host ''
Write-Host "  XONG. Da cap nhat len ban $moi." -ForegroundColor Green

# ---------- Mo lai MicroStation voi ban ve dang lam ----------
$dgn = ''
if (Test-Path $MoLaiFile) {
    $dgn = (Get-Content $MoLaiFile -Encoding UTF8 -TotalCount 1)
    Remove-Item $MoLaiFile -ErrorAction SilentlyContinue
}
if ($exe -and (Test-Path $exe)) {
    Write-Host '  Dang mo lai MicroStation ...'
    if ($dgn -and (Test-Path $dgn)) { Start-Process -FilePath $exe -ArgumentList ('"' + $dgn + '"') }
    else { Start-Process -FilePath $exe }
} else {
    Write-Host '  Mo lai MicroStation de dung ban moi.'
}
Write-Host '  (Cua so nay tu dong sau 5 giay)'
Start-Sleep -Seconds 5
exit 0
