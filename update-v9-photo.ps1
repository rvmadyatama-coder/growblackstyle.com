
# GrowBlackStyle V9 Photo System
# SAFE MODE:
# - Reads hotel names/locations from hotel-OLD
# - Builds NEW pages in hotel-V9-STAGING
# - Does NOT modify hotel
# - Does NOT modify sitemap
# - Does NOT push GitHub
# - Uses Wikimedia Commons files only when the file metadata shows a suitable
#   free/public-domain license.
#
# Run:
#   Set-ExecutionPolicy -Scope Process Bypass
#   cd C:\GROWBLACK-GITHUB
#   .\update-v9-photo.ps1 -Limit 10
#
# First test 10 pages. If correct:
#   .\update-v9-photo.ps1
#
# The script prefers a hotel-specific image. If none is found, it uses a
# location/destination image and labels it as an editorial destination image.
# It records source, author and license in image-credit.txt and in the HTML.

param(
    [int]$Limit = 0
)

$ErrorActionPreference = "Stop"

$root = "C:\GROWBLACK-GITHUB"
$oldRoot = Join-Path $root "hotel-OLD"
$staging = Join-Path $root "hotel-V9-STAGING"
$ga = "G-08V5WW63RS"
$site = "https://growblackstyle.com"

if (!(Test-Path $oldRoot)) {
    throw "hotel-OLD tidak ditemukan: $oldRoot"
}

if (Test-Path $staging) {
    Remove-Item $staging -Recurse -Force
}
New-Item -ItemType Directory -Path $staging | Out-Null

$used = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

function Html([string]$s) {
    return [System.Net.WebUtility]::HtmlEncode($s)
}

function Slug([string]$s) {
    $x = $s.ToLowerInvariant()
    $x = $x -replace '&amp;', 'and'
    $x = $x -replace '[^a-z0-9]+','-'
    $x = $x.Trim('-')
    return $x
}

function Get-OldHotelData($file) {
    $html = Get-Content $file -Raw -Encoding UTF8

    $hm = [regex]::Match($html, '(?is)<h1[^>]*>(.*?)</h1>')
    if (!$hm.Success) { return $null }

    $hotel = [System.Net.WebUtility]::HtmlDecode(
        ($hm.Groups[1].Value -replace '<[^>]+>',' ')
    ).Trim()

    $dm = [regex]::Match($html, '(?is)<meta\s+name=["'']description["'']\s+content=["'']Research candidate for .*?\bin\s+(.+?)\.\s+The property identity')
    $location = ""
    if ($dm.Success) {
        $location = [System.Net.WebUtility]::HtmlDecode($dm.Groups[1].Value).Trim()
    }

    if (!$location) {
        $lm = [regex]::Match($html, '(?is)HOTEL GUIDE\s*[·•]\s*([^<]+)')
        if ($lm.Success) { $location = [System.Net.WebUtility]::HtmlDecode($lm.Groups[1].Value).Trim() }
    }

    if (!$location) { $location = "International destination" }

    return [PSCustomObject]@{
        Hotel = $hotel
        Location = $location
        Slug = (Slug $hotel)
    }
}

function Invoke-CommonsSearch([string]$query, [int]$limit=20) {
    $q = [uri]::EscapeDataString($query)
    $url = "https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch=$q&gsrnamespace=6&gsrlimit=$limit&prop=imageinfo&iiprop=url%7Cextmetadata%7Cmime%7Csize&iiurlwidth=1600&format=json"
    return Invoke-RestMethod -Uri $url -Headers @{ "User-Agent" = "GrowBlackStyle/1.0 editorial-site contact" }
}

function Get-LicenseText($info) {
    $m = $info.extmetadata
    if ($null -eq $m) { return "" }
    if ($m.LicenseShortName -and $m.LicenseShortName.value) { return [string]$m.LicenseShortName.value }
    if ($m.License -and $m.License.value) { return [string]$m.License.value }
    return ""
}

function Find-CommonsImage([string]$hotel, [string]$location) {
    $queries = @(
        "`"$hotel`"",
        "$hotel $location",
        "$location hotel architecture",
        "$location travel"
    )

    foreach ($query in $queries) {
        try {
            $data = Invoke-CommonsSearch $query 30
        } catch {
            continue
        }

        if ($null -eq $data.query.pages) { continue }

        foreach ($p in $data.query.pages.PSObject.Properties) {
            $page = $p.Value
            if ($null -eq $page.imageinfo) { continue }
            $ii = $page.imageinfo[0]

            $mime = [string]$ii.mime
            if ($mime -notmatch '^image/(jpeg|png|webp)$') { continue }
            if ([int64]$ii.width -lt 900 -or [int64]$ii.height -lt 500) { continue }

            $license = Get-LicenseText $ii
            if (!$license) { continue }

            # Avoid clearly non-commercial licenses.
            if ($license -match '(?i)non.?commercial|\bNC\b') { continue }

            $url = [string]$ii.thumburl
            if (!$url) { $url = [string]$ii.url }
            if (!$url) { continue }

            if ($used.Contains($url)) { continue }

            $author = ""
            if ($ii.extmetadata.Artist) { $author = [string]$ii.extmetadata.Artist.value }
            $title = [System.Net.WebUtility]::HtmlDecode([string]$page.title)
            $source = "https://commons.wikimedia.org/wiki/$([uri]::EscapeDataString($title.Replace(' ','_')))"

            $isHotel = $false
            $hay = ($page.title + " " + $query)
            $hotelWords = ($hotel -split '\s+' | Where-Object { $_.Length -ge 4 })
            $matchCount = 0
            foreach ($w in $hotelWords) {
                if ($hay -match [regex]::Escape($w)) { $matchCount++ }
            }
            if ($hotelWords.Count -gt 0 -and $matchCount -ge [Math]::Max(2, [Math]::Ceiling($hotelWords.Count * 0.45))) {
                $isHotel = $true
            }

            $used.Add($url) | Out-Null

            return [PSCustomObject]@{
                Url = $url
                License = $license
                Author = $author
                Source = $source
                HotelSpecific = $isHotel
                Title = $title
            }
        }
    }

    return $null
}

function ArticleText([string]$hotel,[string]$location,[int]$n) {
    $angles = @(
        "location and first impressions",
        "neighborhood access and trip planning",
        "design, setting and travel experience",
        "who the location is best suited to",
        "how to evaluate a stay here",
        "the surrounding destination",
        "planning a city break around the property",
        "what to consider before booking"
    )
    $angle = $angles[$n % $angles.Count]

    $h = Html $hotel
    $l = Html $location

    return @"
<h2>${h}: an editorial hotel guide</h2>
<p>$h is a hotel in $l. This GrowBlackStyle guide looks at the property through the lens of <strong>$angle</strong>. The aim is to help travelers understand the setting, compare practical considerations and decide whether the destination fits the kind of trip they are planning.</p>

<h2>Location and travel context</h2>
<p>The location is an important part of the decision. A hotel in $l can be evaluated not only by the room itself, but also by how easily a traveler can reach the areas, attractions, restaurants and transport connections that matter to the trip. Before booking, map the places you expect to visit and compare the real travel time from the property rather than relying only on a neighborhood label.</p>

<h2>What to consider before booking</h2>
<p>Travelers should compare the available room categories, cancellation rules, taxes, resort or destination charges where applicable, breakfast inclusions, parking arrangements and the conditions attached to promotional rates. These details can materially change the final cost of a stay.</p>

<h2>Who may prefer this type of stay?</h2>
<p>$h may appeal to travelers whose plans are centered on $l and who value convenient access to the destination. Couples, leisure travelers and visitors building a city itinerary can benefit from comparing the hotel's position with alternative properties in the same area.</p>

<h2>Planning the surrounding trip</h2>
<p>A useful approach is to build the itinerary around geographic clusters. Group nearby attractions together, identify the closest public-transport options and allow extra time for airport transfers and peak-period traffic. This can make a centrally located hotel more valuable than a superficially cheaper property farther away.</p>

<h2>Questions worth checking with the hotel</h2>
<p>Because rates, facilities and operating policies can change, verify current information directly before paying a non-refundable rate. Confirm check-in and check-out times, available room types, accessibility information, parking, pet policies and any mandatory fees that may not appear in the headline room price.</p>

<h2>GrowBlackStyle Editorial Verdict</h2>
<p>$h is best evaluated in the context of $l rather than by room price alone. Its strongest potential advantage is the experience created by its location and the convenience that location can provide during a trip. Travelers should compare the complete booking cost and current hotel policies before making a final decision.</p>

<div class="editor-note"><strong>Editorial note:</strong> This page uses original GrowBlackStyle editorial wording. Hotel names and location information are provided for informational purposes. Current hotel facilities, prices and policies should be verified with the property before booking.</div>
"@
}

$files = Get-ChildItem $oldRoot -Directory | Sort-Object Name
if ($Limit -gt 0) { $files = $files | Select-Object -First $Limit }

$count = 0
$failed = 0

foreach ($dir in $files) {
    $old = Join-Path $dir.FullName "index.html"
    if (!(Test-Path $old)) { continue }

    $d = Get-OldHotelData $old
    if ($null -eq $d) { $failed++; continue }

    $img = Find-CommonsImage $d.Hotel $d.Location
    if ($null -eq $img) {
        Write-Warning "Tidak menemukan gambar bebas yang layak: $($d.Hotel)"
        $failed++
        continue
    }

    $outDir = Join-Path $staging $dir.Name
    New-Item -ItemType Directory -Path $outDir | Out-Null

    $ext = if ($img.Url -match '\.png($|\?)') { "png" } elseif ($img.Url -match '\.webp($|\?)') { "webp" } else { "jpg" }
    $imagePath = Join-Path $outDir "hotel-hero.$ext"

    try {
        Invoke-WebRequest -Uri $img.Url -OutFile $imagePath -Headers @{ "User-Agent" = "GrowBlackStyle/1.0 editorial-site contact" }
    } catch {
        Write-Warning "Gagal download: $($d.Hotel)"
        $failed++
        continue
    }

    $safeHotel = Html $d.Hotel
    $safeLocation = Html $d.Location
    $safeSlug = Html $dir.Name
    $canonical = "$site/hotel/$safeSlug/"
    $imageRel = "./hotel-hero.$ext"

    $photoLabel = if ($img.HotelSpecific) { "Hotel image" } else { "Editorial destination image" }

    $html = @"
<!doctype html>
<html lang="en" translate="no">
<head>
<meta charset="utf-8">
<meta name="google" content="notranslate">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$safeHotel — Hotel Guide | GrowBlackStyle</title>
<meta name="description" content="Editorial hotel guide for $safeHotel in $safeLocation, covering location, trip planning and practical booking considerations.">
<meta name="robots" content="index,follow">
<link rel="canonical" href="$canonical">
<script async src="https://www.googletagmanager.com/gtag/js?id=$ga"></script>
<script>
window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}
gtag('js',new Date());gtag('config','$ga');
</script>
<style>
body{margin:0;color:#171717;background:#fff;font-family:Arial,sans-serif;line-height:1.75}
header{border-bottom:1px solid #eee;padding:22px 5%;font-family:Georgia,serif;font-size:25px;font-weight:bold}
nav{float:right;font-family:Arial,sans-serif;font-size:13px;font-weight:normal}
nav a{margin-left:20px;color:#333;text-decoration:none}
.wrap{max-width:1180px;margin:55px auto;padding:0 24px}
.grid{display:grid;grid-template-columns:minmax(0,1fr) 300px;gap:55px}
.eyebrow{font-size:12px;letter-spacing:.12em;text-transform:uppercase;color:#777}
h1,h2,h3{font-family:Georgia,serif;line-height:1.2}
h1{font-size:52px;margin:14px 0 28px}
h2{font-size:30px;margin-top:44px}
.hero{width:100%;max-height:620px;object-fit:cover;display:block;margin:0 0 12px}
.photo-credit{font-size:11px;color:#777;margin-bottom:30px}
.sidebar{border-left:1px solid #eee;padding-left:25px}
.ad{min-height:250px;border:1px solid #eee;display:flex;align-items:center;justify-content:center;color:#999;margin-bottom:30px}
.editor-note{border-top:1px solid #eee;margin-top:40px;padding-top:20px;font-size:13px;color:#666}
footer{border-top:1px solid #eee;margin-top:70px;padding:30px 5%;font-size:12px;color:#777}
@media(max-width:800px){nav{float:none;margin-top:10px}nav a{margin:0 14px 0 0}.grid{grid-template-columns:1fr}.sidebar{border-left:0;padding-left:0}h1{font-size:38px}}
</style>
</head>
<body>
<header>GROWBLACKSTYLE
<nav><a href="/">HOTELS</a><a href="/destinations/">DESTINATIONS</a><a href="/travel-guides/">TRAVEL GUIDES</a><a href="/about/">ABOUT</a></nav>
</header>
<main class="wrap">
<div class="grid">
<article>
<div class="eyebrow">HOTEL GUIDE · $safeLocation</div>
<h1>$safeHotel</h1>
<img class="hero" src="$imageRel" alt="$safeHotel — $photoLabel" loading="eager">
<div class="photo-credit">$photoLabel. Source: Wikimedia Commons. Author: $(Html $img.Author). License: $(Html $img.License). <a href="$(Html $img.Source)" rel="nofollow">Image source</a>.</div>
$(ArticleText $d.Hotel $d.Location $count)
</article>
<aside class="sidebar">
<div class="ad">Advertisement</div>
<h3>Recent Posts</h3>
<p>Hotel guides and destination planning from GrowBlackStyle.</p>
</aside>
</div>
</main>
<footer>© GrowBlackStyle · Independent hotel and travel editorial.</footer>
</body>
</html>
"@

    [System.IO.File]::WriteAllText((Join-Path $outDir "index.html"), $html, (New-Object System.Text.UTF8Encoding($false)))

    $credit = @"
Hotel: $($d.Hotel)
Location: $($d.Location)
Image: $($img.Title)
Author: $($img.Author)
License: $($img.License)
Source: $($img.Source)
Image URL: $($img.Url)
Type: $photoLabel
"@
    [System.IO.File]::WriteAllText((Join-Path $outDir "image-credit.txt"), $credit, (New-Object System.Text.UTF8Encoding($false)))

    $count++
    Write-Host "[$count] $($d.Hotel) -> $photoLabel"
}

Write-Host ""
Write-Host "SELESAI"
Write-Host "Staging : $staging"
Write-Host "Berhasil: $count"
Write-Host "Gagal  : $failed"
Write-Host ""
Write-Host "JANGAN hapus hotel dan JANGAN push GitHub sebelum staging diperiksa."




