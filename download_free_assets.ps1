$key = Get-Content "$PSScriptRoot\.polyforkAPI" -Raw | ForEach-Object { $_.Trim() }
$base = "https://polyfork.dev"
$outDir = "$PSScriptRoot\downloads"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$headers = @{ "Authorization" = "Bearer $key" }

# --- collect all free assets ---
$all = @()
$page = 1
do {
    $resp = Invoke-RestMethod "$base/api/assets?free=1&per_page=100&page=$page" -Headers $headers
    $all += $resp.assets
    Write-Host "Page $page — $($resp.assets.Count) assets (total so far: $($all.Count) / $($resp.total))"
    $page++
} while ($all.Count -lt $resp.total)

Write-Host "`nDownloading $($all.Count) free assets...`n"

$ok = 0; $fail = 0

foreach ($asset in $all) {
    # fetch detail to get correct download URLs
    $detail = Invoke-RestMethod "$base/api/assets/$($asset.id)" -Headers $headers
    $dl = $detail.download

    # use title for a readable folder name, fall back to id
    $safeName = ($detail.title -replace '[\\/:*?"<>|]', '_') 
    if (-not $safeName) { $safeName = $asset.id }
    $dir = Join-Path $outDir $safeName
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $success = $true
    foreach ($ext in @("glb", "mjs")) {
        $url = $dl.$ext
        if (-not $url) { continue }
        $dest = Join-Path $dir "$($asset.id).$ext"
        if (Test-Path $dest) { continue }   # already downloaded
        try {
            $dlHeaders = if ($dl.auth -eq "none") { @{} } else { $headers }
            Invoke-WebRequest $url -Headers $dlHeaders -OutFile $dest -ErrorAction Stop
        } catch {
            Write-Warning "  FAIL $ext $($asset.id): $($_.Exception.Message)"
            $success = $false
        }
    }

    if ($success) {
        $ok++
        Write-Host "  [OK] $safeName"
    } else {
        $fail++
    }
}

Write-Host "`nDone. $ok succeeded, $fail failed."
Write-Host "Files saved to: $outDir"
