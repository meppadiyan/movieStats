#curl -H "Authorization: token <GITHUB_ACCESS_TOKEN>" https://api.github.com/repos/<OWNER>/<REPO>/contents/<FOLDER_PATH>
#$url = "https://api.github.com/repos/HedCET/paytm-movies/contents/Malikappuram"
#$url = "https://api.github.com/repos/HedCET/bms/contents/BheeshmaParvam"
#$url = "https://api.github.com/repos/HedCET/paytm-movies/contents/BheeshmaParvam"
#$url = "https://api.github.com/repos/HedCET/bms/contents/Pathaan"
#$url = "https://api.github.com/repos/HedCET/bms/contents/Thankam"
#$url = "https://api.github.com/repos/HedCET/bms/contents/NanpakalNerathuMayakkam"
#$url = "https://api.github.com/repos/HedCET/bms/contents/JayaJayaJayaJayaHey"
$filmName = "BheeshmaParvam"
#$filmName = "Malikappuram"
$bmsUrl = "https://api.github.com/repos/HedCET/bms/contents/" + $filmName
$paytmUrl = "https://api.github.com/repos/HedCET/paytm-movies/contents/" + $filmName
Class MovieStatsCompiled {
            [string]$description
            [string]$bms_show_count
            [string]$bms_amount
            [string]$paytm_show_count
            [string]$paytm_amount
            [string]$source}
[MovieStatsCompiled[]] $csvData = @()
$movieDataHash = @{}

$webData = Invoke-WebRequest -Uri $bmsUrl
$statsByDate = ConvertFrom-Json $webData.content
$total = 0

$statsByDate | foreach{
    $_.name -match '\d\d\d\d-\d\d-\d\d'
    $dateVal = $matches[0]
    $_.download_url
    $webDataDate = Invoke-WebRequest -Uri $_.download_url
    $webDataCSV = ConvertFrom-CSV $webDataDate.content
    $totalBusinessForTheDay = 0
    $webDataCSV | foreach{
        $price = $_.Price.replace('₹','')
        #if($_.State -eq "Kerala"){
            $totalBusinessForTheDay += [math]::Round($price) * $_.Booked
        #}
    }
    $movieStatsCompiled = [MovieStatsCompiled]::new()
    if ($movieDataHash[$dateVal] -eq $null ){
       # $movieStatsCompiled = [MovieStatsCompiled]::new()
       $movieDataHash[$dateVal] =  $movieStatsCompiled
       $movieStatsCompiled.description = $dateVal
    }else{
        $movieStatsCompiled = $movieDataHash[$dateVal]
    }
    $count = 0
    if($webDataCSV -ne $null){
        $count = $webDataCSV.Count
    }
    $movieStatsCompiled.bms_show_count = $count.ToString()
    $movieStatsCompiled.bms_amount = $totalBusinessForTheDay.ToString()
    $fileNameLast = Split-Path $_.download_url -leaf
    $movieStatsCompiled.source = "https://github.com/HedCET/bms/tree/main/" + $filmName + "/" + $fileNameLast
    $movieDataHash[$dateVal] = $movieStatsCompiled
    #$movieDataHash[$dateVal] = $webDataCSV.Count.ToString() + "-" +  $totalBusinessForTheDay.ToString()
    $total += $totalBusinessForTheDay
}
$total
$webData = Invoke-WebRequest -Uri $paytmUrl
$statsByDate = ConvertFrom-Json $webData.content


$statsByDate | foreach{
    $_.name -match '\d\d\d\d-\d\d-\d\d'
    $dateVal = $matches[0]
    $_.download_url
    $webDataDate = Invoke-WebRequest -Uri $_.download_url
    $webDataCSV = ConvertFrom-CSV $webDataDate.content
    $totalBusinessForTheDay = 0
    $webDataCSV | foreach{
        $price = $_.Price.replace('₹','')
        #if($_.State -eq "Kerala"){
            $totalBusinessForTheDay += [math]::Round($price) * $_.Booked
        #}
    }
    $movieStatsCompiled = [MovieStatsCompiled]::new()
    if ($movieDataHash[$dateVal] -eq $null ){
       # $movieStatsCompiled = [MovieStatsCompiled]::new()
       $movieDataHash[$dateVal] =  $movieStatsCompiled
       $movieStatsCompiled.description = $dateVal
    }else{
        $movieStatsCompiled = $movieDataHash[$dateVal]
    }
    $count = 0
    if(($webDataCSV -ne $null) -and ($webDataCSV.Count -ne $null)){
        $count = $webDataCSV.Count
    }
    $movieStatsCompiled.paytm_show_count = $count.ToString()
    $movieStatsCompiled.paytm_amount = $totalBusinessForTheDay.ToString()
    $fileNameLast = Split-Path $_.download_url -leaf
    $delimiter = "_"
    if($movieStatsCompiled.source -ne $null -and $movieStatsCompiled.source.toString() -eq ""){
        $delimiter = ""
    }
    $movieStatsCompiled.source = $movieStatsCompiled.source + $delimiter + "https://github.com/HedCET/paytm-movies/tree/main/" + $filmName + "/" + $fileNameLast
    $movieDataHash[$dateVal] = $movieStatsCompiled
    #$movieDataHash[$dateVal] = $webDataCSV.Count.ToString() + "-" +  $totalBusinessForTheDay.ToString()
    $total += $totalBusinessForTheDay
}

$sortedHashmap = $movieDataHash.GetEnumerator() | Sort-Object -Property Name
$output = "";
$sortedHashmap.ForEach{
    $output += "`n " + $_.Value.description + "," + $_.Value.bms_show_count + "," + $_.Value.bms_amount + "," +  $_.Value.paytm_show_count + "," + $_.Value.paytm_amount + "," + $_.Value.source
    $_.Value.description + "," + $_.Value.bms_show_count + "," + $_.Value.bms_amount + "," +  $_.Value.paytm_show_count + "," + $_.Value.paytm_amount + "," + $_.Value.source
}
$output | Out-File "C:\Temp\bheemshma.csv"
$total
