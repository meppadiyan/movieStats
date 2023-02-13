Class MovieStats {
            [int]$totalShows
            [int]$totalSeatsBooked
            [int]$totalSeatsAvailabe
            [string]$occupancy
            [String[]]$eventCinemaSessions = @()
            [String[]]$hoytsCinemaSessions = @()
            [String]$outputMessage
            [String] $movieDate
            [String] $movieName
            [String] $movieVistaIdHoyts
            [String] $movieFolderId
            [String[]] $eventCinemaIds = @()
            [String[]] $hoytsCinemaIds = @()
            [String] $cinemaType
            [String] $csvGithubURL
            [psobject[]] $csvData = @()

            MovieStats([String]$movieName,[String] $movieFolderId,[String] $movieVistaIdHoyts,[String[]]$eventCinemaIds,[String[]] $hoytsCinemaIds,[String] $movieDate){
                $this.movieName     = $movieName
                $this.movieFolderId = $movieFolderId
                $this.movieVistaIdHoyts = $movieVistaIdHoyts
                $this.eventCinemaIds     = $eventCinemaIds
                $this.hoytsCinemaIds     = $hoytsCinemaIds
                $this.movieDate     = $movieDate
                $this.csvGithubURL  = "https://api.github.com/repos/meppadiyan/movieStats/contents/stats/" + $this.movieFolderId +"/" + $this.movieDate + ".csv"
            }

            Init(){
                $this.updateCSVData()
                $this.eventCinemaIds | foreach{
                    $this.UpdateEventMovieSessionByCinemaId($_)
                }
                $this.hoytsCinemaIds | foreach{
                   $this.UpdateHOYTSMovieSessionByCinemaId($_)
                }
                $this.UpdateEventCinemaSessions()
                $this.UpdateHOYTSCinemaSessions()
               
            }

            WriteOutputLine([Boolean] $verbose,[String] $message){
                $this.outputMessage += "`n" + $message
            }


            <#MovieStats([String[]]$eventCinemaSessions,[String[]]$hoytsCinemaSessions){
                $this.eventCinemaSessions = $eventCinemaSessions
                $this.hoytsCinemaSessions = $hoytsCinemaSessions
            }#>

            updateCSVData(){
                try{
                    $url = "https://raw.githubusercontent.com/meppadiyan/movieStats/main/stats/"+ $this.movieFolderId +"/" + $this.movieDate + ".csv"
                    $this.outputMessage += "`n" + "Url to get existing data = " + $url 
                    #$url = "https://raw.githubusercontent.com/meppadiyan/movieStats/main/stats/Thankam/2023-01-29.csv"
                    $webData = Invoke-WebRequest -Uri $url
                    $this.csvData = ConvertFrom-Csv $webData.content
                }catch{
                    $this.outputMessage += "`n" + "Error Happened"
                }
                $this.outputMessage += "`n" + "---------------total emenets in CSV data after init" + $this.csvData.Count.ToString()
            }

            updateCSVSingleRecord([psobject] $item){
            #$this.csvData += $item
            #return;
                 $this.outputMessage += "`n" + "---------------total emenets in CSV data before updating " + $item.SessionId +  " = " + $this.csvData.Count.ToString()
                 $this.outputMessage += "`n" + "Call came here"
                 $isItemExisting = $false;
                 foreach($element in $this.csvData){
                    #$this.outputMessage += "`n" + "Matching " + $element.SessionId + " and " + $item.SesssionId
                    if($element.SessionId -eq $item.SessionId){
                        #Object.assign($element, $item)
                        $element.Showtime = $item.Showtime
                        $element.SeatsRemaining = $item.SeatsRemaining
                        $element.Booked = $item.Booked
                        $element.Location= $item.Location
                        $element.MovieName= $item.MovieName
                        $element.Available = $item.Available
                        $element.Occupancy = $item.Occupancy
                        $element.CostPerTicket = "20$ approx"
                        $element.TotalCost = $item.totalCost
                        $element.LastUpdatedOn = $(Get-Date)
                        $element.Mode = "Auto"
                        $isItemExisting = $true
                    }
                 }

                if($isItemExisting -eq $false){
                    $this.csvData += $item
                    #$this.outputMessage += "`n" + "Adding csv data"
                }else{
                #$this.outputMessage += "`n" + "it is true"
                }
            }

            UpdateEventMovieSessionByCinemaId([String] $cinemaId){
                $cinemaIdURl = "https://www.eventcinemas.com.au/Cinemas/GetSessions?cinemaIds="+$cinemaId.ToString()+"&date=" + $this.movieDate
                #$this.outputMessage += "`n" + "Calling cinema url = " + $cinemaIdURl
                try{
                    $webData = Invoke-WebRequest -Uri $cinemaIdURl
                    $movieSession = ConvertFrom-Json $webData.content
                    $movieSession.Data.Movies | foreach {
                        $name = $_.Name
                        #$this.outputMessage += "`n" + "Searching for movie = " + $_.Name + " - " + $this.movieName
                        if($name -match $this.movieName){
                            #$this.outputMessage += "`n" + "Name matches for " + $this.movieName
                            $_.CinemaModels | foreach{
                                $this.outputMessage += "`n" + $_.Id
                                $_.Sessions | foreach{
                                    $this.outputMessage += "`n" + $_.Id
                                    $this.eventCinemaSessions += $_.Id.ToString()
                                    #$this.outputMessage += "`n" + "Adding to event cinema session = " + $_.Id
                                    }
                                }
                        }
                    }
                }
                catch{
                    return;
                }
            }
            UpdateHOYTSMovieSessionByCinemaId([String] $cinemaId){
                $cinemaIdURl = "https://www.hoyts.com.au/api/movie/" + $this.movieVistaIdHoyts.ToString() + "/sessions/" + $cinemaId.ToString()
                try{
                    $webData = Invoke-WebRequest -Uri $cinemaIdURl
                    $movieSession = ConvertFrom-Json $webData.content
                    $movieSession | foreach {
                        if($_.startTime -match $this.movieDate) {
                            $this.hoytsCinemaSessions += $cinemaId + "/" + $_.sessionId.ToString()
                        }
                    }
                }
                catch{
                    return;
                }
            }

            UpdateEventCinemaSessions(){
                $this.eventCinemaSessions | foreach {
                        $url = "https://www.eventcinemas.com.au/api/ticketing/session?sessionId=" + $_
                        $this.outputMessage += "`n" + "Calling url = " + $url 
                        $sessionId = $_
                        $state    = ""
                        $location = ""
                        $screen   = ""
                        $screentype = ""
                        $showtime = ""
                        $capacity = "0"
                        $brand    = ""
                        try{
                         $webData = Invoke-WebRequest -Uri $url
                         $movieSession = ConvertFrom-Json $webData.content
                         $seatsBooked = 0
                         $seatsAvailable = 0

                         $state    = $movieSession.Data.Cinema.State
                         $location = $movieSession.Data.Cinema.Suburb
                         $screen   = $movieSession.Data.Session.ScreenName
                         $showtime = $movieSession.Data.SessionDetails.StartTimeDesc
                         $movName   = $movieSession.Data.SessionDetails.MovieName
                         $capacity = $movieSession.Data.Session.SeatsAvailable
                         $screentype = $movieSession.Data.Session.ScreenTypeName
                         
                         $movieSession.Data.Seats | foreach {
                            $_.Rows | foreach{
                                $_.Seats | foreach{
                                    if ($_.Status -eq "Available"){
                                         $seatsAvailable++
                                    }elseif($_.Status -eq "Booked"){
                                        $seatsBooked++
                                    }
                                }
                            }
                         }
                         $occupancy = "0%"
                         if($seatsBooked -eq 0){
                         }else{
                            $occupancy =  [math]::Round(($seatsBooked / ($seatsBooked + $seatsAvailable) * 100),1).ToString() + "%"
                         }
                         $totalCost = [math]::Round($seatsBooked*20).ToString() + " $"
                         $this.outputMessage += "`n" + "Call came here"
                         $itemObj = New-Object psobject -Property @{
                                                State = $state
                                                Location= $location
                                                MovieName= $movName
                                                Brand = "Event Cinemas"
                                                SessionId = $sessionId
                                                Screen = $screen
                                                Showtime = $showtime
                                                SeatsRemaining = $capacity
                                                Booked = $seatsBooked
                                                Available = $seatsAvailable
                                                Occupancy = $occupancy
                                                CostPerTicket = "20$ approx"
                                                TotalCost = $totalCost
                                                LastUpdatedOn = $(Get-Date)
                                                Mode = "Auto"
                                                }
                         $this.updateCSVSingleRecord($itemObj);

                        }catch{
                        } 
                    }
            }

            UpdateHOYTSCinemaSessions(){
                $this.hoytsCinemaSessions | foreach {
                        $sessionId = $_
                        $state    = ""
                        $location = ""
                        $screen   = ""
                        $screentype = ""
                        $showtime = ""
                        $capacity = "0"
                        $brand    = ""
                        $movName   = ""
                        $url = "";

                        try{
                         $url = "https://www.hoyts.com.au/api/session/" + $_
                         #$this.outputMessage += "`n" + "Calling url = " + $url 
                         $webData = Invoke-WebRequest -Uri $url
                         $movieSession = ConvertFrom-Json $webData.content
                         $screen   = $movieSession.screenName
                         $capacity = $movieSession.sessionCapacity.availableSeats
                         $showtime = [DateTime]$movieSession.startTime
                        }catch{
                            $this.WriteOutputLine($false,"Error Happened while calling url " +  $url)
                        }

                         try{
                         $url = "https://www.hoyts.com.au/api/ticket/" + $_
                         #$this.outputMessage += "`n" + "Calling url = " + $url 
                         $webData = Invoke-WebRequest -Uri $url
                         $movieSession = ConvertFrom-Json $webData.content
                         $movName  = $movieSession.movie
                         $location = $movieSession.cinema
                        }catch{
                            $this.WriteOutputLine($false,"Error Happened while calling url " +  $url)
                        }


                        try{
                            $url = "https://www.hoyts.com.au/api/ticket/seats/" + $_
                            $this.outputMessage += "`n" + "Calling url = " + $url 
                            $webData = Invoke-WebRequest -Uri $url
                            $movieSession = ConvertFrom-Json $webData.content
                            $seatsBooked = 0
                            $seatsAvailable = 0
                            if ($movieSession.areas[0].rows -eq $null ){
                                 $this.outputMessage += Newline + $url
                                 continue
                             }
                            $movieSession.areas[0].rows | foreach {
                                #$this.outputMessage += "`n" + "Physical row id = " + $_.physicalRowId
                                if($_.physicalRowId -ne $null){
                                    $this.outputMessage += "`n" + $_.physicalRowId + " is not null"
                                    $_.seats | foreach{
                                        if($_.status -eq 0){
                                            $seatsAvailable++
                                        }elseif($_.status -eq 1){
                                            $seatsBooked++
                                        }
                                    }
                                }else{
                                    $this.outputMessage += "`n" + $_.physicalRowId + " is null"
                                }
                            }
                            $occupancy = "0%"
                             if($seatsBooked -eq 0){
                             }else{
                                $occupancy =  [math]::Round(($seatsBooked / ($seatsBooked + $seatsAvailable) * 100),1).ToString() + "%"
                             }
                             $totalCost = [math]::Round($seatsBooked*20).ToString() + " $"
                             $this.outputMessage += "`n" + "Call came at hoyttssss here seatsbooked = " + $seatsBooked.ToString()
                             $itemObj = New-Object psobject -Property @{
                                                    State = $state
                                                    Location= $location
                                                    MovieName= $movName
                                                    Brand = "Hoyts Cinemas"
                                                    SessionId = $sessionId
                                                    Screen = $screen
                                                    Showtime = $showtime
                                                    SeatsRemaining = $capacity
                                                    Booked = $seatsBooked
                                                    Available = $seatsAvailable
                                                    Occupancy = $occupancy
                                                    CostPerTicket = "20$ approx"
                                                    TotalCost = $totalCost
                                                    LastUpdatedOn = $(Get-Date)
                                                    Mode = "Auto"
                                                    }
                            $this.updateCSVSingleRecord($itemObj);

                        }catch{
                            $this.WriteOutputLine($false,"Error Happened while calling url " +  $url)
                        }
                    }
            }

            UploadToGithub(){
                [String] $fileNameInsideStatsFolder = $this.movieFolderId +"/" + $this.movieDate + ".csv"
                $contents = ""
                #try{
                    if($this.csvData -eq $null){
                        return
                    }
                    $contents = $this.csvData | Export-Csv -Path "outfile.csv" -NoTypeInformation -Encoding UTF8
                    $contents = Get-Content -Path "outfile.csv" | Out-String
                    #$this.outputMessage += "`n" + "content text =  " + $contents
                  
                   
                <#}catch{
                
                }
                #>
                 # return;
                
                $urlCheck = "https://api.github.com/repos/meppadiyan/movieStats/git/trees/main:stats"
                $sha = ""
                try{
                    $shas = Invoke-WebRequest -Uri $urlCheck
                    $shaTree = ConvertFrom-Json $shas.content
                    $fileShaUrl = ""
                    $shaTree | foreach {
                        $_.tree | foreach{
                            if($_.path -eq $this.movieFolderId){
                                $fileShaUrl = $_.url
                            }
                        }
                    }
                    $fileShas = Invoke-WebRequest -Uri $fileShaUrl 
                    $fileShaTree = ConvertFrom-Json $fileShas.content
                    $fileShaTree | foreach {
                        $_.tree | foreach{
                            if($_.path -eq $this.movieDate + ".csv"){
                                $sha = $_.sha
                            }
                        }
                    }

                }catch{
                }
                
                $url = "https://api.github.com/repos/meppadiyan/movieStats/contents/stats/" + $fileNameInsideStatsFolder;
                $contentType = "application/vnd.github+json"   
                $githubtoken = $env:githubtoken
                #$bearerAuth = "Bearer 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"
                $bearerAuth = "Bearer $githubtoken"
                $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes($contents)
                $content = [System.Convert]::ToBase64String($encodedBytes)

                #$this.outputMessage += "`n" + "decoded text =  " + $contents
                $shaText = "'"  + $sha + "'"

                $jsonText = @"
                {
                    owner: 'meppadiyan',
                    repo: 'movieStats',
                    path: 'main/$fileNameInsideStatsFolder',
                    message: 'Automatic Script Update',
                    committer: {
                    name: 'meppadiyan',
                    email: 'meppadiyan@outlook.com'
                    },
                    content: '$content',
                    sha : '$sha' }
"@
                #$jsonText
                $json = $jsonText |  ConvertFrom-Json | ConvertTo-Json
                 $this.outputMessage += "`n" + "json text =  " + $jsonText
                #$json
                $headers = @{
                    Authorization = $bearerAuth
                };
                $this.WriteOutputLine($false,$githubtoken)
                Invoke-RestMethod -Method PUT -Uri $url -ContentType $contentType -Headers $headers -Body $json
            }
}

$date = "2023-02-14"

$nanpakalMovieStats = [MovieStats]::new("Nanpakal","Nanpakal","",@('19','66','58'),@(),$date)
$nanpakalMovieStats.Init()
$nanpakalMovieStats.UploadToGithub()
$nanpakalMovieStats

$nanpakalMovieStats = [MovieStats]::new("Spadikam","Spadikam","",@('19','66','58'),@(),$date)
$nanpakalMovieStats.Init()
$nanpakalMovieStats.UploadToGithub()
$nanpakalMovieStats

<#$varisuMovieStats = [MovieStats]::new("Varisu","Varisu","",@('58','65','53','21','62','7','19','55','66','69','9'),@(),$date)
$varisuMovieStats.Init()
$varisuMovieStats.UploadToGithub()
$varisuMovieStats#>

$pathaanMovieStats = [MovieStats]::new("Pathaan","Pathaan","HO00007906",@('19','21','53','55','58','62','65','66','69','7','9'),@('MTDRTT','BANKTN','WESCIN','WETHER'),$date)
$pathaanMovieStats.Init()
$pathaanMovieStats.UploadToGithub()
$pathaanMovieStats
