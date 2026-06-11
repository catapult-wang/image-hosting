param(
  [Parameter(Mandatory = $true)]
  [string]$Source,

  [Parameter(Mandatory = $true)]
  [string]$Destination,

  [switch]$Flatten,

  [string]$Message
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$sourcePath = Resolve-Path $Source
$destinationPath = $Destination.Trim("/\")
$destinationFsPath = Join-Path $repoRoot ("images\" + $destinationPath.Replace("/", "\"))
$extensions = @(".png", ".jpg", ".jpeg", ".webp", ".gif", ".svg")

New-Item -ItemType Directory -Force -Path $destinationFsPath | Out-Null

$images = Get-ChildItem -LiteralPath $sourcePath -Recurse -File |
  Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() } |
  Sort-Object FullName

if ($images.Count -eq 0) {
  throw "No supported image files found in $sourcePath"
}

$copied = @()
$seenNames = @{}

foreach ($image in $images) {
  if ($Flatten) {
    $relativeName = $image.Name
    if ($seenNames.ContainsKey($relativeName)) {
      throw "Duplicate filename found while using -Flatten: $relativeName"
    }
    $seenNames[$relativeName] = $true
  } else {
    $relativeName = [IO.Path]::GetRelativePath($sourcePath, $image.FullName)
  }

  $target = Join-Path $destinationFsPath $relativeName
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
  Copy-Item -LiteralPath $image.FullName -Destination $target -Force
  $copied += $relativeName.Replace("\", "/")
}

$remote = git -C $repoRoot remote get-url origin
if ($remote -notmatch "github\.com[:/](?<owner>[^/]+)/(?<repo>[^/.]+)(\.git)?$") {
  throw "Cannot parse GitHub remote URL: $remote"
}

$owner = $Matches.owner
$repo = $Matches.repo

git -C $repoRoot add images

$status = git -C $repoRoot status --short
if ($status) {
  if (-not $Message) {
    $Message = "Publish images to images/$destinationPath"
  }
  git -C $repoRoot commit -m $Message
  git -C $repoRoot push
} else {
  Write-Output "No file changes to publish."
}

$baseUrl = "https://$owner.github.io/$repo/images/" + $destinationPath.Replace("\", "/")
Write-Output ""
Write-Output "Published URLs:"
foreach ($item in $copied) {
  Write-Output "$baseUrl/$item"
}
