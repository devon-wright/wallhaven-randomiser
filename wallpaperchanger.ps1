#########
#OPTIONS, CHANGE THE ABOVE URL TO THE ONES BELOW
#Presets:

#I WANT SKETCHY/NSFW STUFF TOO
# https://wallhaven.cc/search?categories=111&purity=010&sorting=random&order=desc

# NO ANIME (dont do this, no fun)
# https://wallhaven.cc/search?categories=100&purity=100&sorting=random&order=desc

#NO ANIME AND HIGH RES
# https://wallhaven.cc/search?categories=100&purity=100&atleast=2560x1440&sorting=random&order=desc

# I want HIGH RES (2560x1440) or set to any other BLAxBLA for a resolution you want
#https://wallhaven.cc/search?categories=110&purity=100&atleast=2560x1440&sorting=random&order=desc

# &categories="110" explanation:
# bitmap flags 
# first bit = general on/off, second bit = anime on/off, third bit = people on/off
# EXAMPLE:
# 111 = general,anime,people
# 011 = anime,people
# 100 = just general
#$categoriesCode = "100"

# &purity="100" explanation:
# 100 = SFW
# 110 = SFW AND NSFW
# 010 = JUST NSFW
#$purityCode = "100"

# Level of resolution minimum
#$resolution = "2560x1440"

# Parameters for script, defaults are overridden if exe called with values
param($categoryType = "100", $purityType = "100", $resolutionLevel = "2560x1440", [Parameter(Mandatory = $false)]$logPath)

# URL of the website
$url = "https://wallhaven.cc/search?categories=${categoryType}&purity=${purityType}&atleast=${resolutionLevel}&sorting=random&order=desc"

#########

# CSS selector for the list item
$liSelector = "li"

# CSS selector for the section
$sectionSelector = 'section class="thumb-listing-page"'
$imagePath = "$env:TEMP\wallpaper.jpg"

$failed = 0

function DownloadImage() {
    # Download the HTML content of the website
    $html = Invoke-WebRequest -Uri  $url -UseBasicParsing

    # Find the section with the specified class
    $sectionTag = $html.RawContent -match "<$sectionSelector>(.*?)</section>"

    # Check if a section tag was found
    if ($Matches.Count -gt 0) {
        # Find all unordered lists within the section
        $ulTags = $Matches[0] -split "<ul[^>]*>"

        # Check if unordered lists were found
        if ($ulTags.Count -gt 1) {
            # Extract the content of the first list item within the first unordered list
            $firstListItemContent = $ulTags[1] -match "<$liSelector.*?>(.*?)</$liSelector>"

            # Check if a list item was found
            if ($Matches.Count -gt 0) {
                # Extract the text content of the first list item
                $firstListItemText = $Matches[1].Trim()
                Write-Host "Found section"
            }
            else {
                Write-Host "List item not found based on the provided list item selector."
            }
        }
        else {
            Write-Host "No unordered lists found within the section."
        }
    }
    else {
        Write-Host "Section with class '$sectionSelector' not found on the page."
    }


    #when the url is https://wallhaven.cc/w/dpovpm for example
    #the full image will be https://w.wallhaven.cc/full/dp/wallhaven-dpovpm.jpg
    # see how the dp part is is split

    # Use regular expression to extract the href value
    $hrefPattern = 'href="([^"]+)"'
    $match = [regex]::Match($firstListItemText, $hrefPattern)

    # Check if a match is found
    if ($match.Success) {
        $hrefValue = $match.Groups[1].Value
        # Write-Output $hrefValue
    }
    else {
        Write-Output "Href not found in the input string."
    }

    #we only care about the last 6 characters of the url
    $hrefValue = $hrefValue[-6..-1] -join ''
    $firstTwoChars = $hrefValue.Substring(0, 2)
    $newUrl = "https://w.wallhaven.cc/full/${firstTwoChars}/wallhaven-${hrefValue}.jpg"
    
    Write-Output "Url is ${newUrl}"
    Write-Output "Downloading..."
    # Use Invoke-WebRequest to download the image
    try {
        Invoke-WebRequest -Uri  $newUrl -OutFile $imagePath -UseBasicParsing
        $failed = 0
        
        if ( $null -ne $logPath) {
            try {
                # Save the filename to a file (create file if it doesn't exist)
                $filePath = "${logPath}\imageHistory.log"
                $currDate = Get-Date -UFormat "%m-%d-%Y_%H-%M-%S" 
                "[${currDate}] ${newURL}" | Out-File -FilePath $filePath -Append -Encoding utf8
            }
            catch {
                Write-Error $_
            }
        }
    }
    catch {

        Write-Host "Image not found. Restarting the script..."
        $failed = 1
        DownloadImage
    }

}

function SetImage() {
    # Set the desktop background
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
"@

    # Constants for SystemParametersInfo
    $SPI_SETDESKWALLPAPER = 0x0014
    $SPIF_UPDATEINIFILE = 0x01
    $SPIF_SENDCHANGE = 0x02

    # Set the desktop background
    [Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $imagePath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)

}

#main
DownloadImage

Write-Output "Setting as wallpaper..."
SetImage

Write-Output "Done!"