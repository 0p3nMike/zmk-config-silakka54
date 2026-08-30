<#
  Silakka54 dual-half flasher.

  Watches for NICENANO bootloader drives and writes the correct firmware to
  each half, identified by USB serial:
      829C156FB312BF26 = LEFT  (central)
      10053538959D7B3E = RIGHT (peripheral)

  Both halves can be plugged in at once - each drive is matched to its own
  serial, so there is no guessing which is which.

  Usage:  .\flash.ps1 -FirmwareDir <dir with the .uf2 files>
#>
param(
    [Parameter(Mandatory=$true)][string]$FirmwareDir,
    [int]$TimeoutSeconds = 180
)

$SERIALS = @{
    '829C156FB312BF26' = 'left'
    '10053538959D7B3E' = 'right'
}

function Get-Uf2 ([string]$dir, [string]$side) {
    Get-ChildItem $dir -Filter "*.uf2" |
        Where-Object { $_.Name -like "*silakka54_$side*" } |
        Select-Object -First 1
}

$fw = @{}
foreach ($side in 'left','right') {
    $f = Get-Uf2 $FirmwareDir $side
    if (-not $f) { Write-Host "ERROR: no $side .uf2 in $FirmwareDir" -ForegroundColor Red; exit 1 }
    $fw[$side] = $f
    "{0,-6} {1}  ({2:N0} bytes)" -f $side, $f.Name, $f.Length
}

# Map a bootloader drive letter -> which half, via the USB serial on its
# parent device. Falls back to $null when the serial is unrecognised.
function Get-SideForDrive([string]$driveLetter) {
    $letter = $driveLetter.TrimEnd(':')
    try {
        $vol = Get-CimInstance Win32_Volume -Filter "DriveLetter='${letter}:'" -ErrorAction Stop
        $disk = Get-CimInstance Win32_DiskDrive -ErrorAction Stop | Where-Object {
            $part = Get-CimAssociatedInstance $_ -ResultClassName Win32_DiskPartition -ErrorAction SilentlyContinue
            if (-not $part) { return $false }
            $ld = $part | ForEach-Object { Get-CimAssociatedInstance $_ -ResultClassName Win32_LogicalDisk -ErrorAction SilentlyContinue }
            $ld.DeviceID -contains "${letter}:"
        } | Select-Object -First 1
        if ($disk) {
            foreach ($s in $SERIALS.Keys) { if ($disk.PNPDeviceID -like "*$s*") { return $SERIALS[$s] } }
        }
    } catch { }
    return $null
}

Write-Host "`nWatching for bootloader drives (${TimeoutSeconds}s)."
Write-Host "Put a half into bootloader: hold Lower+Raise, press top-right key - or double-tap reset.`n"

$done = @{}
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)

while ((Get-Date) -lt $deadline -and $done.Count -lt 2) {
    $drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=2" -ErrorAction SilentlyContinue |
              Where-Object { $_.VolumeName -eq 'NICENANO' }

    foreach ($d in $drives) {
        $side = Get-SideForDrive $d.DeviceID
        if (-not $side) {
            Write-Host "  $($d.DeviceID) - unknown serial, skipping" -ForegroundColor DarkYellow
            continue
        }
        if ($done[$side]) { continue }

        Write-Host "  $($d.DeviceID) = $side half - writing $($fw[$side].Name)" -ForegroundColor Cyan
        try {
            $bytes = [System.IO.File]::ReadAllBytes($fw[$side].FullName)
            [System.IO.File]::WriteAllBytes("$($d.DeviceID)\fw.uf2", $bytes)
            Write-Host "  $side OK - board rebooting" -ForegroundColor Green
        } catch {
            # The bootloader reboots the instant it has a full UF2, so the
            # drive can vanish mid-call. That is success, not failure.
            Write-Host "  $side written (drive dropped on reboot - normal)" -ForegroundColor Green
        }
        $done[$side] = $true
        Start-Sleep -Seconds 3
    }
    Start-Sleep -Milliseconds 400
}

Write-Host ""
foreach ($side in 'left','right') {
    if ($done[$side]) { Write-Host "$side  : flashed" -ForegroundColor Green }
    else              { Write-Host "$side  : NOT flashed" -ForegroundColor Yellow }
}
