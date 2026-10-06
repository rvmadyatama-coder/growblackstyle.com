$root = "C:\GROWBLACK-GITHUB\hotel"

$files = Get-ChildItem $root -Directory | ForEach-Object {
    Join-Path $_.FullName "index.html"
}

foreach ($file in $files) {

    $html = Get-Content $file -Raw

    # Ambil nama hotel dari H1
    $h1Match = [regex]::Match($html, '<h1[^>]*>(.*?)</h1>', 'IgnoreCase')

    if (-not $h1Match.Success) {
        continue
    }

    $hotel = [System.Net.WebUtility]::HtmlDecode(
        ($h1Match.Groups[1].Value -replace '<[^>]+>', '').Trim()
    )

    # Ambil lokasi dari bagian Hotel Guide
    $locationMatch = [regex]::Match(
        $html,
        'Hotel Guide\s*[·•]\s*(.*?)\s*[·•]\s*Updated',
        'IgnoreCase'
    )

    if ($locationMatch.Success) {
        $location = $locationMatch.Groups[1].Value.Trim()
    }
    else {
        $location = "International destination"
    }

    $parts = $location -split ',\s*', 2

    if ($parts.Count -eq 2) {
        $city = $parts[0].Trim()
        $country = $parts[1].Trim()
    }
    else {
        $city = $location
        $country = ""
    }

    # Breadcrumb
    if ($country) {
        $breadcrumb = "Home / Hotels / $country / $city"
    }
    else {
        $breadcrumb = "Home / Hotels / $city"
    }

    # Meta description
    $description = "An independent GrowBlackStyle editorial guide to $hotel in $location, covering location, trip planning, stay considerations and questions to check before booking."

    # Artikel
    $article = @"
<p>$hotel is a hotel property associated with $location. This GrowBlackStyle guide provides an independent starting point for travelers researching where to stay and how to evaluate a hotel before making a booking.</p>

<p>Rather than reproducing promotional material, this guide focuses on practical travel questions: where the property is located, what kind of trip the area may suit, what travelers should investigate before booking, and which details should be confirmed against current official information.</p>

<h2>About $hotel</h2>

<p>When researching $hotel, the first step is to establish the property's current identity and location. Hotel names, room categories, facilities and policies can change over time, so travelers should confirm important details directly with the property's current official source before making a reservation.</p>

<h2>Location and Area</h2>

<p>$hotel is listed in $city, $country. The surrounding area can have a significant effect on the experience of a hotel stay, particularly for travelers who plan to spend most of their time exploring the destination rather than staying at the property.</p>

<p>Before booking, consider the distance to the places you expect to visit, available transportation, the character of the surrounding neighborhood and how convenient the location will be during the hours you are most likely to travel.</p>

<h2>What Travelers Should Check Before Booking</h2>

<h3>Room and Stay Options</h3>

<p>Room categories and inclusions should be checked against the hotel's current official information. Travelers should pay attention to room size, occupancy limits, bed configuration, cancellation conditions and whether the selected rate includes the services they actually need.</p>

<h3>Total Cost</h3>

<p>The advertised room price is not always the final amount paid. Before confirming a reservation, check taxes, service charges, resort or destination fees, breakfast arrangements, parking and any other mandatory charges that may apply.</p>

<h3>Check-in and Check-out</h3>

<p>Arrival and departure policies are important when planning flights, trains or other transportation. Confirm the current check-in and check-out times and whether early arrival or late departure is available.</p>

<h2>Who Might Consider This Hotel?</h2>

<p>$hotel may be worth considering for travelers whose plans fit the property's location and current offering. The best choice depends on the purpose of the trip, preferred neighborhood, budget, transportation needs and the type of accommodation experience being sought.</p>

<p>Travelers comparing several hotels should evaluate location and total trip cost alongside the room price. A hotel that appears more expensive can sometimes be more convenient if it reduces transportation time and additional daily expenses.</p>

<h2>Questions to Answer Before Booking</h2>

<ul>
<li>Is the location convenient for the main places you plan to visit?</li>
<li>What is included in the selected room rate?</li>
<li>Are there mandatory fees or additional taxes?</li>
<li>What are the current cancellation and payment conditions?</li>
<li>What are the current check-in and check-out times?</li>
<li>Are the facilities and services you need currently available?</li>
<li>Does the hotel suit the purpose and budget of your trip?</li>
</ul>

<h2>Practical Research Checklist</h2>

<p>Before booking $hotel, compare the hotel's current official information with the reservation rate you are considering. Pay particular attention to dates, room type, occupancy, cancellation terms and the final price rather than relying only on the headline nightly rate.</p>

<p>Travel conditions can also change. Transportation, nearby attractions, hotel policies and available services may differ from older reviews or articles, so recent information is generally more useful when making a final decision.</p>

<h2>Frequently Asked Questions</h2>

<h3>Where is $hotel?</h3>

<p>$hotel is listed in $location. Travelers should confirm the property's current address and map location before booking.</p>

<h3>Is $hotel suitable for my trip?</h3>

<p>That depends on your itinerary, budget, preferred location and the facilities you require. Comparing those factors with the hotel's current official information is the best way to determine whether it is a suitable choice.</p>

<h3>Should I check the hotel's official website before booking?</h3>

<p>Yes. Current room availability, pricing, policies, facilities and fees can change. The official hotel source should be used to confirm important details before a reservation is made.</p>

<h2>Editorial Verdict</h2>

<p>$hotel is a property worth researching if its location and current offering match the needs of your trip. The strongest way to evaluate it is not simply by looking at the room price, but by considering location, total cost, transportation, room requirements and current hotel policies together.</p>

<p><strong>Our recommendation:</strong> use this page as a starting point for research, then verify the important booking details against current official information before making a reservation.</p>
"@

    # Ganti breadcrumb
    $html = [regex]::Replace(
        $html,
        '<div class="breadcrumb.*?</div>',
        "<div class=`"breadcrumb`">$breadcrumb</div>",
        'IgnoreCase, Singleline'
    )

    # Ganti meta description
    $html = [regex]::Replace(
        $html,
        '<meta\s+name="description"\s+content=".*?">',
        "<meta name=`"description`" content=`"$description`">",
        'IgnoreCase'
    )

    # Cari gambar hero dan ganti seluruh isi artikel setelah gambar
    $articlePattern = '(?s)(<img[^>]+>).*?(?=<h2|</article>)'

    if ([regex]::IsMatch($html, $articlePattern, 'IgnoreCase')) {
        $html = [regex]::Replace(
            $html,
            $articlePattern,
            "`$1`n$article`n",
            'IgnoreCase'
        )
    }

    Set-Content $file $html -Encoding UTF8
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "SELESAI MEMPERBARUI HALAMAN HOTEL" -ForegroundColor Green
Write-Host "Total halaman diproses: $($files.Count)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green