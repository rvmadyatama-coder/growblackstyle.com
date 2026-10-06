$root = "C:\GROWBLACK-GITHUB"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   GROWBLACKSTYLE ADSENSE AUDIT MASSAL" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Cari SEMUA index.html di dalam project
$files = Get-ChildItem $root -Recurse -File -Filter "index.html" |
    Where-Object {
        $_.FullName -notmatch "\\hotel-V9-STAGING\\" -and
        $_.FullName -notmatch "\\\.git\\" -and
        $_.FullName -notmatch "\\node_modules\\"
    }

Write-Host "Index.html ditemukan : $($files.Count)" -ForegroundColor Yellow
Write-Host ""

$results = @()

foreach ($file in $files) {

    try {
        $html = Get-Content $file.FullName -Raw -ErrorAction Stop
    }
    catch {
        continue
    }

    # TITLE
    $m = [regex]::Match($html,'(?is)<title[^>]*>(.*?)</title>')
    $title = if ($m.Success) {
        ($m.Groups[1].Value -replace '\s+',' ').Trim()
    } else { "" }

    # META DESCRIPTION
    $m = [regex]::Match(
        $html,
        '(?is)<meta[^>]+name\s*=\s*["'']description["''][^>]+content\s*=\s*["''](.*?)["'']'
    )

    if (!$m.Success) {
        $m = [regex]::Match(
            $html,
            '(?is)<meta[^>]+content\s*=\s*["''](.*?)["''][^>]+name\s*=\s*["'']description["'']'
        )
    }

    $description = if ($m.Success) {
        $m.Groups[1].Value.Trim()
    } else { "" }

    # H1 / H2
    $h1 = ([regex]::Matches($html,'(?is)<h1\b')).Count
    $h2 = ([regex]::Matches($html,'(?is)<h2\b')).Count

    # IMAGES
    $imgs = [regex]::Matches($html,'(?is)<img\b[^>]*>')
    $imageCount = $imgs.Count
    $missingAlt = 0

    foreach ($img in $imgs) {
        if ($img.Value -notmatch '(?i)\balt\s*=\s*["''][^"'']*["'']') {
            $missingAlt++
        }
    }

    # CANONICAL
    $canonical = [regex]::IsMatch(
        $html,
        '(?is)<link[^>]+rel\s*=\s*["'']canonical["'']'
    )

    # TEXT / WORD COUNT
    $text = [regex]::Replace(
        $html,
        '(?is)<script.*?</script>|<style.*?</style>|<[^>]+>',
        ' '
    )

    $text = [System.Net.WebUtility]::HtmlDecode($text)

    $words = @(
        $text -split '\s+' |
        Where-Object {
            $_ -match '[A-Za-zÀ-ÿ0-9]'
        }
    ).Count

    # INTERNAL LINKS
    $internalLinks = 0

    foreach ($a in [regex]::Matches(
        $html,
        '(?is)<a\b[^>]+href\s*=\s*["'']([^"'']+)["'']'
    )) {

        $href = $a.Groups[1].Value.Trim()

        if ($href -notmatch '^(https?:|mailto:|tel:|#|javascript:)') {
            $internalLinks++
        }
    }

    # RELATIVE PATH
    $relative = $file.FullName.Substring($root.Length).TrimStart('\')

    $issues = @()

    if (!$title) {
        $issues += "NO_TITLE"
    }

    if (!$description) {
        $issues += "NO_META"
    }

    if ($h1 -eq 0) {
        $issues += "NO_H1"
    }

    if ($h1 -gt 1) {
        $issues += "MULTIPLE_H1"
    }

    if ($imageCount -eq 0) {
        $issues += "NO_IMAGE"
    }

    if ($missingAlt -gt 0) {
        $issues += "MISSING_ALT"
    }

    if (!$canonical) {
        $issues += "NO_CANONICAL"
    }

    if ($words -lt 300) {
        $issues += "THIN_CONTENT"
    }

    if ($internalLinks -eq 0) {
        $issues += "NO_INTERNAL_LINK"
    }

    $status = "GREEN"

    if (
        $issues -contains "NO_TITLE" -or
        $issues -contains "NO_H1" -or
        $issues -contains "NO_IMAGE" -or
        $issues -contains "THIN_CONTENT"
    ) {
        $status = "RED"
    }
    elseif ($issues.Count -gt 0) {
        $status = "YELLOW"
    }

    $results += [PSCustomObject]@{
        Path            = $relative
        Title           = if ($title) {"YES"} else {"NO"}
        TitleLength     = $title.Length
        Meta            = if ($description) {"YES"} else {"NO"}
        MetaLength      = $description.Length
        H1              = $h1
        H2              = $h2
        Images          = $imageCount
        MissingAlt      = $missingAlt
        Canonical       = if ($canonical) {"YES"} else {"NO"}
        Words           = $words
        InternalLinks   = $internalLinks
        Status          = $status
        Issues          = ($issues -join ",")
    }
}

# CSV
$csv = Join-Path $root "growblackstyle-adsense-audit.csv"

$results |
    Export-Csv $csv -NoTypeInformation -Encoding UTF8

# SUMMARY
$total = $results.Count
$green = @($results | Where-Object Status -eq "GREEN").Count
$yellow = @($results | Where-Object Status -eq "YELLOW").Count
$red = @($results | Where-Object Status -eq "RED").Count

$noTitle = @($results | Where-Object Title -eq "NO").Count
$noMeta = @($results | Where-Object Meta -eq "NO").Count
$noH1 = @($results | Where-Object H1 -eq 0).Count
$noImage = @($results | Where-Object Images -eq 0).Count
$thin = @($results | Where-Object Words -lt 300).Count
$noCanonical = @($results | Where-Object Canonical -eq "NO").Count
$missingAlt = @($results | Where-Object MissingAlt -gt 0).Count

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "              HASIL AUDIT" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Total halaman       : $total"
Write-Host "GREEN               : $green" -ForegroundColor Green
Write-Host "YELLOW              : $yellow" -ForegroundColor Yellow
Write-Host "RED                 : $red" -ForegroundColor Red

Write-Host ""
Write-Host "Tanpa TITLE         : $noTitle"
Write-Host "Tanpa META          : $noMeta"
Write-Host "Tanpa H1            : $noH1"
Write-Host "Tanpa GAMBAR        : $noImage"
Write-Host "Konten < 300 kata   : $thin"
Write-Host "Tanpa CANONICAL     : $noCanonical"
Write-Host "Ada ALT yang hilang : $missingAlt"

Write-Host ""
Write-Host "CSV:"
Write-Host $csv -ForegroundColor Cyan

Write-Host ""
Write-Host "AUDIT SELESAI - FILE WEBSITE TIDAK DIUBAH" -ForegroundColor Green
