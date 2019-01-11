#Gets the download speed 12 times and calculates the average speed
Function Servers($svr1)
{
    #Runs a speed test on the  the highest result.
    $DLResults1 = downloadSpeed($svr1)
    $SpeedResults1 = [int]$DLResults1
    $DLResults2 = downloadSpeed($svr1)
    $SpeedResults2 = [int]$DLResults2
    $DLResults3 = downloadSpeed($svr1)
    $SpeedResults3 = [int]$DLResults3
    $DLResults4 = downloadSpeed($svr1)
    $SpeedResults4 = [int]$DLResults4
    $DLResults5 = downloadSpeed($svr1)
    $SpeedResults5 = [int]$DLResults5
    $DLResults6 = downloadSpeed($svr1)
    $SpeedResults6 = [int]$DLResults6
    $DLResults7 = downloadSpeed($svr1)
    $SpeedResults7 = [int]$DLResults7
    $DLResults8 = downloadSpeed($svr1)
    $SpeedResults8 = [int]$DLResults8
    $DLResults9 = downloadSpeed($svr1)
    $SpeedResults9 = [int]$DLResults9
    $DLResults10 = downloadSpeed($svr1)
    $SpeedResults10 = [int]$DLResults10
    $DLResults11 = downloadSpeed($svr1)
    $SpeedResults11 = [int]$DLResults11
    $DLResults12 = downloadSpeed($svr1)
    $SpeedResults12 = [int]$DLResults12

    $total = ($SpeedResults1 + $SpeedResults2 + $SpeedResults3 +$SpeedResults4 + $SpeedResults5 + $SpeedResults6 +$SpeedResults7 + $SpeedResults8 + $SpeedResults9 +$SpeedResults10 + $SpeedResults11 + $SpeedResults12)
    $average = $total / 12
    $AvgSpeed = [Math]::Round($average, 2)
    return $AvgSpeed
}

#Downloads a 25 Mb file and calculates the download speed
Function downloadSpeed($strUploadUrl)
{
    $topServerUrlSpilt = ([System.Uri]$strUploadUrl).Host
    $url = 'http://' + $topServerUrlSpilt + ':8080/speedtest/download?nocache=89eacbae-a67d-4b4d-a448-b835d7dc4658&size=25000000'
    $col = new-object System.Collections.Specialized.NameValueCollection 
    $wc = new-object system.net.WebClient 
    $wc.QueryString = $col 
    $downloadElaspedTime = (measure-command {$webpage1 = $wc.DownloadData($url)}).totalmilliseconds
    $string = [System.Text.Encoding]::ASCII.GetString($webpage1)
    $downSize = ($webpage1.length + $webpage2.length) / 1Mb
    $downloadSize = [Math]::Round($downSize, 2)
    $downloadTimeSec = $downloadElaspedTime * 0.001
    $downSpeed = ($downloadSize / $downloadTimeSec) * 8
    $downloadSpeed = [Math]::Round($downSpeed, 2)
	return $downloadSpeed
}

<#
Using this method to make the submission to speedtest. Its the only way i could figure out how to interact with the page since there is no API.
More information for later here: https://support.microsoft.com/en-us/kb/290591
#>
$objXmlHttp = New-Object -ComObject MSXML2.ServerXMLHTTP
$objXmlHttp.Open("GET", "http://www.speedtest.net/speedtest-config.php", $False)
$objXmlHttp.Send()

#Retrieving the content of the response.
[xml]$content = $objXmlHttp.responseText

<#
Gives me the Latitude and Longitude so i can pick the closer server to me to actually test against. It doesnt seem to automatically do this.
Lat and Longitude for tampa at my house are $orilat = 27.9238 and $orilon = -82.3505
This is corroborated against: http://www.travelmath.com/cities/Tampa,+FL - It checks out.
#>
$oriLat = $content.settings.client.lat
$oriLon = $content.settings.client.lon

#Making another request. This time to get the server list from the site.
$objXmlHttp1 = New-Object -ComObject MSXML2.ServerXMLHTTP
$objXmlHttp1.Open("GET", "http://www.speedtest.net/speedtest-servers.php", $False)
$objXmlHttp1.Send()

#Retrieving the content of the response.
[xml]$ServerList = $objXmlHttp1.responseText

<#
$Cons contains all of the information about every server in the speedtest.net database. 
I was going to filter this to US servers only which would speed this up a lot but i know we have overseas partners we run this against. 
Results returned look like this for each individual server:

url     : http://speedtestnet.rapidsys.com/speedtest/upload.php
lat     : 27.9709
lon     : -82.4646
name    : Tampa, FL
country : United States
cc      : US
sponsor : Rapid Systems
id      : 1296

#>
$cons = $ServerList.settings.servers.server 
 
#Below we calculate servers relative closeness to you by doing some math against latitude and longitude. 
foreach($val in $cons) 
{ 
	$R = 6371;
	[float]$dlat = ([float]$oriLat - [float]$val.lat) * 3.14 / 180;
	[float]$dlon = ([float]$oriLon - [float]$val.lon) * 3.14 / 180;
	[float]$a = [math]::Sin([float]$dLat/2) * [math]::Sin([float]$dLat/2) + [math]::Cos([float]$oriLat * 3.14 / 180 ) * [math]::Cos([float]$val.lat * 3.14 / 180 ) * [math]::Sin([float]$dLon/2) * [math]::Sin([float]$dLon/2);
	[float]$c = 2 * [math]::Atan2([math]::Sqrt([float]$a ), [math]::Sqrt(1 - [float]$a));
	[float]$d = [float]$R * [float]$c;
	
	$ServerInformation +=
@([pscustomobject]@{Distance = $d; Country = $val.country; Sponsor = $val.sponsor; Url = $val.url })

}

#sorts the servers by removing duplicates and then by closest
$serverinformation = $serverinformation | Sort-Object -Property sponsor -Unique
$serverinformation = $serverinformation  | Sort-Object -Property distance

#Gets the download speed of 8 of the closest servers
for($s = 0; $s -lt 8; $s++)
{

    $Test1 = Servers($serverinformation[$s].url)
    $SpeedsArray += @([pscustomobject]@{Speed = $Test1;})
}

#Sorts the download speeds by highest speed first
$UnsortedResults = $SpeedsArray | Sort-Object speed -Descending

$WanSpeed = $UnsortedResults[0].speed

#Make sure you create this directory!!!
$WanSpeed | Out-File C:\Apps\Temp\InternetSpeed.txt
