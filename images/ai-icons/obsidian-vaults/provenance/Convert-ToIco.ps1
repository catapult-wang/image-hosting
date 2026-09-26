param([string]$Folder)
Add-Type -AssemblyName System.Drawing
Get-ChildItem -LiteralPath $Folder -Filter 'Obsidian-*.png' | ForEach-Object {
    $img = [System.Drawing.Image]::FromFile($_.FullName)
    $chunks = @()
    foreach ($size in @(16,24,32,48,64,128,256)) {
        $bmp = New-Object System.Drawing.Bitmap($size,$size)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($img,0,0,$size,$size)
        $stream = New-Object System.IO.MemoryStream
        $bmp.Save($stream,[System.Drawing.Imaging.ImageFormat]::Png)
        $chunks += ,($stream.ToArray())
        $stream.Dispose(); $g.Dispose(); $bmp.Dispose()
    }
    $out = [System.IO.File]::Create([System.IO.Path]::ChangeExtension($_.FullName,'.ico'))
    $writer = New-Object System.IO.BinaryWriter($out)
    $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]7)
    $offset = 6 + 16 * 7
    $sizes = @(16,24,32,48,64,128,256)
    for($i=0;$i -lt 7;$i++) {
        $s = $sizes[$i] % 256
        $writer.Write([byte]$s); $writer.Write([byte]$s); $writer.Write([byte]0); $writer.Write([byte]0)
        $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$chunks[$i].Length); $writer.Write([uint32]$offset)
        $offset += $chunks[$i].Length
    }
    foreach($chunk in $chunks){$writer.Write([byte[]]$chunk)}
    $writer.Dispose(); $img.Dispose()
}
