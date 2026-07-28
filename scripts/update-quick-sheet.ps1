param(
  [string]$RepoRoot = ".",
  [string]$OutDir = "generated/quick-sheets",
  [string]$StartMarker = "<!-- QUICK_SHEET_START -->",
  [string]$EndMarker = "<!-- QUICK_SHEET_END -->"
)

$ErrorActionPreference = "Stop"

$repoPath = (Resolve-Path $RepoRoot).Path
$outPath = Join-Path $repoPath $OutDir

# Clean and create output folder
if (Test-Path $outPath) {
  Remove-Item $outPath -Recurse -Force
}
New-Item -ItemType Directory -Path $outPath | Out-Null

$combinedPath = Join-Path $outPath "00-MASTER-QUICK-SHEET.md"
$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$combined = @()
$combined += "# Master Quick Sheet - Interview Revision"
$combined += ""
$combined += "Generated: $generatedAt"
$combined += ""

# Find all markdown files (exclude hidden/generated folders)
$files = Get-ChildItem -Path $repoPath -Recurse -File -Filter "*.md" |
  Where-Object {
    $_.FullName -notmatch "\\\.git\\" -and
    $_.FullName -notmatch "\\\.github\\" -and
    $_.FullName -notmatch "\\generated\\" -and
    $_.FullName -notmatch "\\node_modules\\"
  }

foreach ($file in $files) {
  try {
    $lines = Get-Content -Path $file.FullName -ErrorAction Stop
  }
  catch {
    Write-Warning "Skipped (cannot read): $($file.FullName)"
    continue
  }

  $blocks = @()
  $capture = $false
  $current = @()

  foreach ($line in $lines) {
    if ($line.Trim() -eq $StartMarker) {
      $capture = $true
      $current = @()
      continue
    }
    if ($line.Trim() -eq $EndMarker) {
      if ($capture -and $current.Count -gt 0) {
        $blocks += ,@($current)
      }
      $capture = $false
      $current = @()
      continue
    }
    if ($capture) {
      $current += $line
    }
  }

  # Skip files with no quick sheets
  if ($blocks.Count -eq 0) {
    continue
  }

  # Add to master sheet only (no individual quick sheet files)
  $relative = $file.FullName.Substring($repoPath.Length).TrimStart('\')

  $combined += "---"
  $combined += ""
  $combined += "## $relative"
  $combined += ""
  foreach ($block in $blocks) {
    $combined += $block
    $combined += ""
  }
}

# Write master sheet
Set-Content -Path $combinedPath -Value $combined -Encoding UTF8

Write-Host ""
Write-Host "Master quick sheet generated: $combinedPath"