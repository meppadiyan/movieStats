#curl -H "Authorization: token <GITHUB_ACCESS_TOKEN>" https://api.github.com/repos/<OWNER>/<REPO>/contents/<FOLDER_PATH>
$url = "https://api.github.com/repos/HedCET/paytm-movies/contents/MalikappuramMalayalam"
#$url = "https://api.github.com/repos/HedCET/bms/contents/BheeshmaParvam"
#$url = "https://api.github.com/repos/HedCET/paytm-movies/contents/BheeshmaParvam"
#$url = "https://api.github.com/repos/HedCET/bms/contents/Pathaan"
#$url = "https://api.github.com/repos/HedCET/bms/contents/Thankam"
#$url = "https://api.github.com/repos/HedCET/bms/contents/NanpakalNerathuMayakkam"
#$url = "https://api.github.com/repos/HedCET/bms/contents/JayaJayaJayaJayaHey"

$webData = Invoke-WebRequest -Uri $url
$statsByDate = ConvertFrom-Json $webData.content
$total = 0
$movieDataHash = @{}
$statsByDate | foreach{
    $_.name -match '\d\d\d\d-\d\d-\d\d'
    $dateVal = $matches[0]
    $_.download_url
    $webDataDate = Invoke-WebRequest -Uri $_.download_url
    $webDataCSV = ConvertFrom-CSV $webDataDate.content
    $totalBusinessForTheDay = 0
    $webDataCSV | foreach{
        #if($_.State -eq "Kerala"){
            $totalBusinessForTheDay += $price * $_.Booked
        #}
    }
    $movieDataHash[$dateVal] = $webDataCSV.Count.ToString() + "-" +  $totalBusinessForTheDay.ToString()
    $total += $totalBusinessForTheDay
}
$sortedHashmap = $movieDataHash.GetEnumerator() | Sort-Object -Property Name 
$sortedHashmap 
$total

