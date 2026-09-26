param([string]$Root)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$manifest=Get-Content -LiteralPath "$Root\manifest.json" -Raw -Encoding UTF8 | ConvertFrom-Json
if($manifest.icons.Count -ne 36){throw 'Expected 36 icons'}
$records=@()
foreach($entry in $manifest.icons) {
  $png=Join-Path $Root $entry.png
  $ico=Join-Path $Root $entry.ico
  $im=[System.Drawing.Bitmap]::FromFile($png)
  if($im.Width -ne $im.Height){throw "Not square: $png"}
  if($im.GetPixel(0,0).A -ne 0){throw "Not transparent: $png"}
  $bytes=[System.IO.File]::ReadAllBytes($ico)
  if([BitConverter]::ToUInt16($bytes,2) -ne 1 -or [BitConverter]::ToUInt16($bytes,4) -ne 7){throw "Invalid ICO header: $ico"}
  $sizes=@()
  for($i=0;$i -lt 7;$i++) {
    $pos=6+16*$i
    $size=[int]$bytes[$pos];if($size -eq 0){$size=256};$sizes+=$size
    $len=[BitConverter]::ToUInt32($bytes,$pos+8)
    $offset=[BitConverter]::ToUInt32($bytes,$pos+12)
    if($offset+$len -gt $bytes.Length){throw "Truncated ICO: $ico"}
  }
  if(($sizes -join ',') -ne '16,24,32,48,64,128,256'){throw "Wrong ICO sizes: $ico"}
  $records+=[pscustomobject]@{id=$entry.id;width=$im.Width;height=$im.Height;transparent=$true;icoSizes=$sizes;pngSha256=(Get-FileHash -LiteralPath $png -Algorithm SHA256).Hash;icoSha256=(Get-FileHash -LiteralPath $ico -Algorithm SHA256).Hash}
  $im.Dispose()
}
[pscustomobject]@{count=$records.Count;passed=$true;icons=$records} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath "$Root\validation.json" -Encoding UTF8
Write-Output "Validated $($records.Count) square transparent PNGs and seven-resolution ICOs."
