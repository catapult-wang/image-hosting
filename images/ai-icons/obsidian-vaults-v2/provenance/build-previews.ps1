param([string]$Root)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$manifest=Get-Content -LiteralPath "$Root\manifest.json" -Raw -Encoding UTF8 | ConvertFrom-Json
foreach($section in @('themes','letters')) {
  $files=@(Get-ChildItem -LiteralPath "$Root\$section" -Filter '*.png' | Sort-Object Name)
  if($files.Count -eq 0){continue}
  $cols=if($section -eq 'themes'){5}else{7}
  $rows=[int][Math]::Ceiling($files.Count/$cols)
  $sheet=New-Object System.Drawing.Bitmap(($cols*200),($rows*240))
  $g=[System.Drawing.Graphics]::FromImage($sheet)
  $g.Clear([System.Drawing.Color]::FromArgb(242,242,248))
  $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $font=New-Object System.Drawing.Font('Segoe UI',10)
  for($i=0;$i -lt $files.Count;$i++) {
    $x=($i%$cols)*200; $y=[int][Math]::Floor($i/$cols)*240
    $im=[System.Drawing.Image]::FromFile($files[$i].FullName)
    $g.DrawImage($im,$x+24,$y+8,152,152)
    $label=$files[$i].BaseName.Replace('Obsidian-','')
    $entry=$manifest.icons | Where-Object { [System.IO.Path]::GetFileName($_.png) -eq $files[$i].Name }
    if($entry){$label=$entry.label}
    $g.DrawString($label,$font,[System.Drawing.Brushes]::Black,[single]($x+12),[single]($y+166))
    $g.FillRectangle([System.Drawing.Brushes]::White,$x+12,$y+194,80,36)
    $g.FillRectangle([System.Drawing.Brushes]::Black,$x+100,$y+194,88,36)
    $g.DrawImage($im,$x+18,$y+204,16,16)
    $g.DrawImage($im,$x+44,$y+200,24,24)
    $g.DrawImage($im,$x+106,$y+200,24,24)
    $g.DrawImage($im,$x+142,$y+196,32,32)
    $im.Dispose()
  }
  $sheet.Save("$Root\preview-$section.png",[System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose();$font.Dispose();$sheet.Dispose()
}

