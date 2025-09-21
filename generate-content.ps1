param(
  [string]$root = "."
)

function New-ItemsFromFolder($folder) {
  $items = @()
  $path = Join-Path $root $folder
  if (-not (Test-Path $path)) { return @() }

  Get-ChildItem -Path $path -Include *.md,*.pdf -File | Sort-Object Name | ForEach-Object {
    $fileName = $_.Name
    $rel = "$folder/$fileName" -replace "\\","/"

    $title = $null
    $desc  = $null

    if ($_.Extension -ieq ".md") {
      $raw = Get-Content $_.FullName -Raw
      $h1  = ($raw -split "`n") | Where-Object { $_ -match '^\s*#\s+(.+)$' } | Select-Object -First 1
      if ($h1) { $title = ($h1 -replace '^\s*#\s+','').Trim() }

      # first non-empty paragraph after the H1
      $paras = $raw -split "(\r?\n){2,}"
      $desc  = $paras | Where-Object { $_.Trim() -ne "" } | Select-Object -Skip 1 -First 1
      if ($desc) { $desc = $desc.Trim(); if ($desc.Length -gt 180) { $desc = $desc.Substring(0,180) + "..." } }
    }

    if (-not $title) { $title = [IO.Path]::GetFileNameWithoutExtension($fileName).Replace("_"," ") }
    $id = ($title -replace '[^A-Za-z0-9]+','-').Trim('-').ToLower()

    $items += [pscustomobject]@{
      id         = $id
      title      = $title
      description= $desc
      file       = $rel
      scriptures = @()
      tags       = @()
      posted     = (Get-Item $_.FullName).CreationTimeUtc.ToString("yyyy-MM-dd")
    }
  }
  return $items
}

function Write-Manifest($items, $outFile) {
  $manifest = [ordered]@{
    version = 1
    updated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    items   = $items
  }
  $json = $manifest | ConvertTo-Json -Depth 8
  Set-Content -Path (Join-Path $root $outFile) -Value $json -Encoding UTF8
}

$studies = New-ItemsFromFolder "studies"
$sermons = New-ItemsFromFolder "sermons"

Write-Manifest $studies "studies.json"
Write-Manifest $sermons "sermons.json"
Write-Host "Wrote studies.json and sermons.json."
