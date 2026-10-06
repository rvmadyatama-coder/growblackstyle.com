# GrowBlackStyle V8
# Creates one different editorial article + one different illustrative cover image per hotel.
# Source: hotel-OLD (name + location metadata)
# Output: hotel\
# IMPORTANT: This creates ORIGINAL ILLUSTRATIVE SVG covers, not real hotel photographs.
# Real hotel photography should only be added when you have usage rights.

$ErrorActionPreference = "Stop"

$root = "C:\GROWBLACK-GITHUB"
$source = Join-Path $root "hotel-OLD"
$dest = Join-Path $root "hotel"

if (!(Test-Path $source)) { throw "Folder hotel-OLD tidak ditemukan: $source" }
if (!(Test-Path $dest)) { New-Item -ItemType Directory $dest | Out-Null }

function HtmlDecode([string]$s) {
    return [System.Net.WebUtility]::HtmlDecode($s)
}

function StripHtml([string]$s) {
    $x = $s -replace '(?is)<[^>]+>',' '
    $x = [System.Net.WebUtility]::HtmlDecode($x)
    return (($x -replace '\s+',' ').Trim())
}

function Esc([string]$s) {
    return [System.Net.WebUtility]::HtmlEncode($s)
}

function Get-Tag([string]$html,[string]$tag) {
    $m=[regex]::Match($html,"(?is)<$tag\b[^>]*>(.*?)</$tag>")
    if($m.Success){ return (StripHtml $m.Groups[1].Value) }
    return ""
}

function Get-Meta([string]$html,[string]$name) {
    $m=[regex]::Match($html,"(?is)<meta\b[^>]*name\s*=\s*[""']$name[""'][^>]*content\s*=\s*[""']([^""']*)[""']")
    if($m.Success){ return [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value) }
    $m=[regex]::Match($html,"(?is)<meta\b[^>]*content\s*=\s*[""']([^""']*)[""'][^>]*name\s*=\s*[""']$name[""']")
    if($m.Success){ return [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value) }
    return ""
}

function Get-Location([string]$html) {
    $meta = Get-Meta $html "description"
    $m=[regex]::Match($meta,'(?i)\bin\s+(.+?)\.\s+The property identity')
    if($m.Success){ return $m.Groups[1].Value.Trim() }
    $m=[regex]::Match($html,'(?is)HOTEL GUIDE\s*[·\-]\s*([^<]+)')
    if($m.Success){ return (StripHtml $m.Groups[1].Value).Trim() }
    return "International destination"
}

function SlugTitle([string]$slug) {
    return (($slug -replace '[-_]',' ') -replace '\s+',' ').Trim()
}

function MakeSvg([string]$hotel,[string]$location,[int]$seed,[string]$file) {
    # Unique editorial illustration generated locally. No external image dependency.
    $hue = ($seed * 47) % 360
    $hue2 = ($hue + 55) % 360
    $safeHotel = [System.Security.SecurityElement]::Escape($hotel)
    $safeLoc = [System.Security.SecurityElement]::Escape($location)
    $shortHotel = if($hotel.Length -gt 34){$hotel.Substring(0,34)+"…"}else{$hotel}
    $shortLoc = if($location.Length -gt 42){$location.Substring(0,42)+"…"}else{$location}
    $safeShortHotel = [System.Security.SecurityElement]::Escape($shortHotel)
    $safeShortLoc = [System.Security.SecurityElement]::Escape($shortLoc)

    $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900">
<defs>
 <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
  <stop offset="0%" stop-color="hsl($hue,42%,24%)"/>
  <stop offset="100%" stop-color="hsl($hue2,38%,48%)"/>
 </linearGradient>
 <filter id="blur"><feGaussianBlur stdDeviation="24"/></filter>
</defs>
<rect width="1600" height="900" fill="url(#g)"/>
<circle cx="1260" cy="180" r="190" fill="rgba(255,255,255,.18)" filter="url(#blur)"/>
<circle cx="300" cy="720" r="240" fill="rgba(255,255,255,.10)" filter="url(#blur)"/>
<path d="M0 700 Q220 570 430 690 T850 650 T1250 610 T1600 650 V900 H0Z" fill="rgba(0,0,0,.24)"/>
<path d="M0 770 Q250 650 500 760 T1000 730 T1600 740 V900 H0Z" fill="rgba(0,0,0,.32)"/>
<rect x="92" y="92" width="1416" height="716" rx="38" fill="none" stroke="rgba(255,255,255,.24)" stroke-width="2"/>
<text x="120" y="170" fill="white" font-family="Georgia,serif" font-size="28" letter-spacing="6">GROWBLACKSTYLE · HOTEL GUIDE</text>
<text x="120" y="430" fill="white" font-family="Georgia,serif" font-size="72">$safeShortHotel</text>
<text x="120" y="500" fill="white" opacity=".88" font-family="Arial,sans-serif" font-size="34">$safeShortLoc</text>
<text x="120" y="700" fill="white" opacity=".72" font-family="Arial,sans-serif" font-size="22">EDITORIAL ILLUSTRATION · $seed</text>
</svg>
"@
    [IO.File]::WriteAllText($file,$svg,(New-Object Text.UTF8Encoding($false)))
}

$folders = Get-ChildItem $source -Directory
$count = 0

foreach($dir in $folders) {
    $srcFile = Join-Path $dir.FullName "index.html"
    if(!(Test-Path $srcFile)){ continue }

    $html = Get-Content $srcFile -Raw -Encoding UTF8
    $hotel = Get-Tag $html "h1"
    if([string]::IsNullOrWhiteSpace($hotel)){ $hotel = SlugTitle $dir.Name }
    $location = Get-Location $html

    $safeHotel = Esc $hotel
    $safeLocation = Esc $location
    $canonical = "https://growblackstyle.com/hotel/$($dir.Name)/"
    $desc = Esc "Independent editorial guide to $hotel in $location, with practical planning notes on location, transport, room selection, costs, trip fit and what to verify before booking."

    $seed = [Math]::Abs($dir.Name.GetHashCode())
    $imgName = "editorial-cover.svg"
    $imgPath = Join-Path $dir.FullName $imgName
    MakeSvg $hotel $location $seed $imgPath

    $introVariants = @(
      "$hotel is the kind of property travelers should assess in context: the address, the surrounding area, the purpose of the trip and the total cost can matter as much as the room itself.",
      "A useful way to evaluate $hotel is to start with its destination rather than the room photograph. For a stay in $location, neighborhood, transport and total trip logistics shape the experience.",
      "Choosing a hotel is rarely only about the room. This guide places $hotel in the wider context of $location and focuses on the practical questions travelers should answer before booking.",
      "For travelers considering $hotel, the most useful research begins with the relationship between the property and $location. Location, transport, rate conditions and trip priorities should all be considered together."
    )
    $intro = $introVariants[$seed % $introVariants.Count]

    $angleVariants = @(
      "The strongest planning question is simple: how well does the property support the places you actually intend to visit? A hotel can look attractive on a booking page yet be less convenient if daily journeys are long or require complicated transfers.",
      "Travelers should also separate the advertised room rate from the real trip cost. Taxes, breakfast, parking, resort or destination charges, transport and cancellation conditions can change the value of an apparently inexpensive rate.",
      "Another useful test is to imagine an ordinary day from the property: leaving for breakfast, reaching the first attraction or meeting, returning in the evening, and getting to the airport or station. That exercise often reveals more about hotel convenience than a list of amenities.",
      "The right choice depends on the purpose of the trip. A leisure traveler may prioritize walkability and nearby dining, while a business traveler may value predictable transport and a practical daily routine."
    )
    $angle = $angleVariants[($seed + 1) % $angleVariants.Count]

    $body = @"
<article>
<section class="article-hero">
<img src="/hotel/$($dir.Name)/$imgName" alt="Editorial illustration for $safeHotel in $safeLocation" loading="eager" width="1600" height="900">
</section>

<p class="dek">$safeHotel in $safeLocation: an independent planning guide focused on location, transport, room selection, total cost and trip fit.</p>

<h2>About this hotel guide</h2>
<p>$([System.Net.WebUtility]::HtmlEncode($intro))</p>
<p>GrowBlackStyle approaches hotel pages as travel research rather than as booking listings. The goal is to help a reader identify the questions that matter before spending money. Hotel policies, room inventories, prices and facilities can change, so time-sensitive details should always be checked against a current official source before a reservation is made.</p>

<h2>Location and the shape of the trip</h2>
<p>$([System.Net.WebUtility]::HtmlEncode($angle))</p>
<p>For a stay in $safeLocation, map the property against the places that matter most to your itinerary. Look at walking distances, public transport, road access and the likely journey to the airport or main rail connection. A location that is excellent for one itinerary may be inconvenient for another.</p>

<h3>What to check on the map</h3>
<ul>
<li>Distance to the main places you expect to visit.</li>
<li>Nearest public-transport options and their operating hours.</li>
<li>Airport, station or intercity transfer time.</li>
<li>Evening dining options and the practical route back to the hotel.</li>
<li>Accessibility requirements, if they are important to your trip.</li>
</ul>

<h2>Rooms, rates and the real cost</h2>
<p>The headline rate is only one part of the decision. Compare the same room category across dates and booking channels, then check occupancy, bed configuration, breakfast, taxes, deposits, cancellation terms and payment timing. If parking or other paid services are relevant to your trip, include them in the comparison rather than treating them as separate expenses.</p>
<p>A refundable rate can have a different value from a cheaper non-refundable rate. The best option is not necessarily the lowest number shown first; it is the rate whose conditions match how certain your travel plans are.</p>

<h3>A practical comparison checklist</h3>
<ul>
<li>Room type and maximum occupancy.</li>
<li>Refundable versus non-refundable conditions.</li>
<li>Taxes and mandatory fees.</li>
<li>Breakfast or other inclusions.</li>
<li>Deposit and payment timing.</li>
<li>Parking and transport costs when applicable.</li>
<li>Check-in and check-out rules.</li>
</ul>

<div class="ad"><div><strong>Advertisement</strong><br><span class="small">Advertising is kept separate from editorial content.</span></div></div>

<h2>Who may find this hotel a good fit?</h2>
<p>$safeHotel should be judged against the reason you are visiting $safeLocation. Couples may care about atmosphere and walkability; families may care about room configuration and nearby food; business travelers may care about predictable journeys and a comfortable working routine. The same property can therefore be a strong match for one traveler and a poor match for another.</p>

<h3>For leisure trips</h3>
<p>Build the hotel into the itinerary instead of treating it as a place to sleep only. Check how easily you can reach your highest-priority attractions and whether returning to the property during the day is realistic.</p>

<h3>For business trips</h3>
<p>Consider the morning commute, transport reliability, workspace needs and how easy it is to obtain food or basic services without adding unnecessary travel.</p>

<h3>For families and groups</h3>
<p>Pay close attention to occupancy rules, connecting-room availability, bed arrangements, elevator access and the distance to everyday conveniences. These details can have a larger impact on comfort than a long amenities list.</p>

<h2>How to research $safeHotel before booking</h2>
<p>Start with a current official hotel source for the property's address, policies and room categories. Then compare the exact dates and occupancy you need. Read the cancellation conditions before entering payment details and save the final rate breakdown for your records.</p>
<p>Independent reviews can be useful for identifying recurring practical issues, but they should be treated as evidence to investigate rather than as absolute fact. Look for patterns across multiple recent reviews and distinguish temporary complaints from persistent characteristics of the property or location.</p>

<h2>What can change after publication?</h2>
<p>Hotel information is not static. Rates, fees, opening hours, facilities, renovation status, check-in procedures and transport arrangements may change. This page therefore avoids presenting unverified, time-sensitive hotel claims as permanent facts. Confirm important details directly before travel.</p>

<h2>Frequently asked questions</h2>

<h3>Where is $safeHotel?</h3>
<p>This editorial page places the property in $safeLocation based on the source record used to build the hotel directory. Confirm the current official address before booking or navigating.</p>

<h3>What should I compare before booking?</h3>
<p>Compare the exact room category, dates, occupancy, total price, taxes and fees, cancellation conditions, breakfast or inclusions, and any costs that are relevant to your itinerary.</p>

<h3>Is the cheapest rate always the best?</h3>
<p>No. A lower non-refundable rate may be less suitable than a slightly higher flexible rate if your plans can change. Compare the conditions as well as the price.</p>

<h3>How should I verify hotel facilities?</h3>
<p>Use a current official source for facilities and policies, then use recent independent reviews to identify practical experiences worth checking. Facilities can change, so avoid relying on old screenshots or outdated listings.</p>

<h3>Should I book based only on location?</h3>
<p>Location is important, but it should be considered together with total cost, room conditions, transport, trip purpose and the specific needs of the people traveling.</p>

<h2>GrowBlackStyle Editorial Verdict</h2>
<p>$safeHotel is best evaluated as part of a complete $location trip rather than as an isolated room purchase. The practical priorities are straightforward: confirm the location, calculate the true cost, compare room and cancellation conditions, and make sure the property supports the places and activities that matter most to your itinerary.</p>
<p>The value of a hotel can change significantly depending on dates and traveler needs. For that reason, this guide is designed to support research and comparison rather than to make a blanket claim that one property is right for everyone.</p>

<div class="editor-note"><strong>Editorial note:</strong> GrowBlackStyle uses original editorial wording and illustrative artwork on this page. Hotel names and destination references are used for informational travel research. Current hotel facts, policies, prices and photography should be verified with appropriate official sources and rights holders.</div>
</article>
"@

    $css = @'
body{margin:0;background:#fff;color:#171717;font-family:Arial,Helvetica,sans-serif}
.wrap{max-width:1180px;margin:auto;padding:28px 22px}
.nav{display:flex;gap:26px;align-items:center;border-bottom:1px solid #e8e8e8;padding:10px 0 24px;font-size:14px}
.nav a{font-family:Georgia,serif;color:#111;text-decoration:none;font-weight:700;letter-spacing:.4px}
.navlinks{margin-left:auto;display:flex;gap:18px}.navlinks a{font-family:Arial;font-weight:600}
.layout{display:grid;grid-template-columns:minmax(0,1fr) 310px;gap:58px;margin-top:52px}
.article h1{font-family:Georgia,serif;font-size:clamp(42px,6vw,74px);line-height:1.02;margin:0 0 20px;font-weight:500}
.meta{font-size:12px;letter-spacing:1.8px;text-transform:uppercase;color:#777;margin-bottom:22px}
.article{font-size:17px;line-height:1.82}.article p{color:#333}.article h2{font-family:Georgia,serif;font-size:31px;line-height:1.2;margin:48px 0 16px}.article h3{font-size:21px;margin:32px 0 10px}
.article ul{padding-left:24px}.article li{margin:8px 0}
.article-hero{margin:0 0 28px}.article-hero img{display:block;width:100%;height:auto}
.dek{font-family:Georgia,serif;font-size:22px;line-height:1.5;color:#333}
.sidebar{font-size:14px}.ad{min-height:180px;border:1px solid #e5e5e5;display:grid;place-items:center;text-align:center;color:#888;margin-bottom:26px}.small{font-size:12px;color:#999}
.sidebox{border-top:1px solid #ddd;padding-top:20px;margin-top:28px}.sidebox h3{font-family:Georgia,serif;font-size:20px;margin:0 0 12px}.sidebox a{color:#222;text-decoration:none}
.editor-note{margin-top:45px;padding:18px;background:#f6f6f3;font-size:13px;line-height:1.6;color:#666}
.footer{border-top:1px solid #ddd;margin-top:70px;padding:28px 0;color:#777;font-size:13px}
@media(max-width:800px){.layout{grid-template-columns:1fr;gap:35px}.navlinks{display:none}.wrap{padding:20px 16px}.article{font-size:16px}}
'@

    $htmlOut = @"
<!doctype html>
<html lang="en" translate="no">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="google" content="notranslate">
<title>$safeHotel — Hotel Guide | GrowBlackStyle</title>
<meta name="description" content="$desc">
<meta name="robots" content="index,follow">
<link rel="canonical" href="$canonical">
<meta property="og:type" content="article">
<meta property="og:title" content="$safeHotel — Hotel Guide | GrowBlackStyle">
<meta property="og:description" content="$desc">
<meta property="og:url" content="$canonical">
<meta property="og:image" content="https://growblackstyle.com/hotel/$($dir.Name)/$imgName">
<script async src="https://www.googletagmanager.com/gtag/js?id=G-08V5WW63RS"></script>
<script>
window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}
gtag('js',new Date());gtag('config','G-08V5WW63RS');
</script>
<style>$css</style>
</head>
<body>
<div class="wrap">
<header class="nav">
<a href="/">GROWBLACKSTYLE</a>
<div class="navlinks">
<a href="/hotels/">HOTELS</a><a href="/destinations/">DESTINATIONS</a><a href="/travel-guides/">TRAVEL GUIDES</a><a href="/about/">ABOUT</a>
</div>
</header>
<div class="layout">
<main class="article">
<div class="meta">Hotel Guide · $safeLocation</div>
<h1>$safeHotel</h1>
$body
</main>
<aside class="sidebar">
<div class="ad"><div><strong>Advertisement</strong><br><span class="small">Advertising is kept separate from editorial content.</span></div></div>
<div class="sidebox"><h3>Recent Posts</h3><p><a href="/hotel/">Explore the hotel guide</a></p><p><a href="/destinations/">Explore destinations</a></p><p><a href="/travel-guides/">Read travel guides</a></p></div>
</aside>
</div>
<footer class="footer">© GrowBlackStyle · Independent hotel & travel editorial</footer>
</div>
</body>
</html>
"@

    $outDir = Join-Path $dest $dir.Name
    if(!(Test-Path $outDir)){ New-Item -ItemType Directory $outDir | Out-Null }
    [IO.File]::WriteAllText((Join-Path $outDir "index.html"),$htmlOut,(New-Object Text.UTF8Encoding($false)))
    $count++
}

Write-Host ""
Write-Host "SELESAI: $count halaman dibuat."
Write-Host "Sumber: hotel-OLD"
Write-Host "Output: hotel"
Write-Host "Setiap halaman memiliki artikel editorial berbeda berdasarkan hotel + lokasi."
Write-Host "Setiap halaman memiliki cover SVG berbeda."
Write-Host ""
Write-Host "JANGAN PUSH GITHUB sebelum audit."
