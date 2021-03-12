<#


.DESCRIPTION
    Help functions for Epinova/LOL check website extension.
#>

Set-StrictMode -Version Latest

class TestResult {
    [bool]$Error
    [string]$TestName
    [string]$Time
    [string]$Description
}

function PrintSitemapTestResultXml{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $testResultFileName,
        [Parameter(Mandatory = $true)]
        [object] $testResultList,
        [Parameter(Mandatory = $true)]
        [string] $baseUrl,
        [Parameter(Mandatory = $true)]
        [long] $testTimerSeconds,
        [Parameter(Mandatory = $false)]
        [string] $filePath
    )

    $errorResults = $testResultList | Where-Object {$_.StatusCode -ne 200 -and $_.StatusCode -ne 301}
    $numberOfFailed = 0
    if ($null -ne $errorResults){
        Write-Warning "Errors"
        $numberOfFailed = $errorResults.Count
    }

    $uri = [System.Uri]$baseUrl
    $hostname = $uri.IdnHost

    if ($null -ne $filePath -and $filePath.Length -ne 0 -and $filePath.EndsWith('\') -ne $true){
        $filePath = $filePath + "\"
    }
    if ($testResultFileName.Contains("€hostname") -eq $false){
        Write-Error "Param testResultFileName does not contains €hostname."
    }
    if ($testResultFileName.Contains("€dateTime") -eq $false){
        Write-Error "Param testResultFileName does not contains €dateTime."
    }

    $dateTime = Get-Date -Format "yyyyMMddTHHmmss"
    $testResultFileName = $testResultFileName -replace "€hostname", $hostname
    $testResultFileName = $testResultFileName -replace "€dateTime", $dateTime

    $fileName = $filePath + $testResultFileName
    Write-Host "Create result file: $fileName"
    $xmlWriter = New-Object System.XMl.XmlTextWriter($fileName,$Null)
    $xmlWriter.Formatting = 'Indented'
    $xmlWriter.Indentation = 1
    $xmlWriter.IndentChar = "`t"
    $xmlWriter.WriteStartDocument()

    $xmlWriter.WriteStartElement('testsuites')
    $xmlWriter.WriteAttributeString('name', 'check-website-test-suite')
    $xmlWriter.WriteAttributeString('tests', $testResultList.Count)
    $xmlWriter.WriteAttributeString('time', $testTimerSeconds)
    $xmlWriter.WriteAttributeString('failures', $numberOfFailed)

    $xmlWriter.WriteStartElement('testsuite')
    $xmlWriter.WriteAttributeString('tests', $testResultList.Count)
    $xmlWriter.WriteAttributeString('timestamp', (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"))

    $totalNumber = $testResultList.Count
    $iterator = 1
    $procentageCompleteOld = 0
    $lastWrittenProcentage = 0

    foreach ($result in $testResultList){
        $resultUrl = $result.Url
        $className = $hostname
        if ($result.StatusCode -eq 200 -or $result.StatusCode -eq 301) {
            $xmlWriter.WriteStartElement('testcase')
            $xmlWriter.WriteAttributeString('classname', $className)
            $xmlWriter.WriteAttributeString('name', $resultUrl)
            $xmlWriter.WriteAttributeString('time', $result.Time)
            $xmlWriter.WriteEndElement() #/testcase
        }
        else #if ($result.Result -eq 2) 
        {
            $xmlWriter.WriteStartElement('testcase')
            $xmlWriter.WriteAttributeString('classname', $className)
            $xmlWriter.WriteAttributeString('name', $resultUrl)
            $xmlWriter.WriteAttributeString('time', $result.Time)
                $xmlWriter.WriteStartElement('failure')
                $xmlWriter.WriteAttributeString('type', $result.HttpStatus)
                $xmlWriter.WriteString($result.Description)
                $xmlWriter.WriteEndElement() #/failure
            $xmlWriter.WriteEndElement() #/testcase
        }

        $procentageComplete = [math]::Truncate(($iterator / $totalNumber) * 100)
        if ($procentageComplete -ne $procentageCompleteOld){
            Write-Progress -Activity "Write test result XML" -Status "$procentageComplete% Complete:" -PercentComplete $procentageComplete;
            $procentageCompleteOld = $procentageComplete
        }
        if (($procentageComplete % 10) -eq 0 -and $lastWrittenProcentage -ne $procentageComplete){
            Write-Host "Write test result XML: $procentageComplete% Complete."
            $lastWrittenProcentage = $procentageComplete
        }
        $iterator++;
    }

    $xmlWriter.WriteEndElement() #/testsuite
    $xmlWriter.WriteEndElement() #/testsuites

    $xmlWriter.WriteEndDocument()
    $xmlWriter.Flush()
    $xmlWriter.Close()

    # <testsuites name='my-test-suite' tests='3' time='0.3' failures='1'>
    #     <testsuite tests='3' timestamp='2020-05-14T12:35:00'>
    #         <testcase classname='foo1' name='ASuccessfulTest' time='0.1'/>
    #         <testcase classname='foo2' name='AnotherSuccessfulTest' time='0.1'/>
    #         <testcase classname='foo3' name='AFailingTest' time='0.1'>
    #             <failure type='NotEnoughFoo'> details about failure </failure>
    #         </testcase>
    #     </testsuite>
    # </testsuites>

}

function PrintGenericTestResultXml{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $testResultFileName,
        [Parameter(Mandatory = $true)]
        [object] $testResultList,
        [Parameter(Mandatory = $true)]
        [string] $baseUrl,
        [Parameter(Mandatory = $true)]
        [long] $testTimerSeconds,
        [Parameter(Mandatory = $false)]
        [string] $filePath
    )

    $errorResults = $testResultList | Where-Object {$_.Error}
    $numberOfFailed = 0
    if ($null -ne $errorResults){
        Write-Warning "Errors"
        $numberOfFailed = $errorResults.Count
    }

    $uri = [System.Uri]$baseUrl
    $hostname = $uri.IdnHost

    if ($null -ne $filePath -and $filePath.Length -ne 0 -and $filePath.EndsWith('\') -ne $true){
        $filePath = $filePath + "\"
    }
    if ($testResultFileName.Contains("€hostname") -eq $false){
        Write-Error "Param testResultFileName does not contains €hostname."
    }
    if ($testResultFileName.Contains("€dateTime") -eq $false){
        Write-Error "Param testResultFileName does not contains €dateTime."
    }

    $dateTime = Get-Date -Format "yyyyMMddTHHmmss"
    $testResultFileName = $testResultFileName -replace "€hostname", $hostname
    $testResultFileName = $testResultFileName -replace "€dateTime", $dateTime

    $fileName = $filePath + $testResultFileName
    Write-Host "Create result file: $fileName"
    $xmlWriter = New-Object System.XMl.XmlTextWriter($fileName,$Null)
    $xmlWriter.Formatting = 'Indented'
    $xmlWriter.Indentation = 1
    $xmlWriter.IndentChar = "`t"
    $xmlWriter.WriteStartDocument()

    $xmlWriter.WriteStartElement('testsuites')
    $xmlWriter.WriteAttributeString('name', 'check-website-test-suite')
    $xmlWriter.WriteAttributeString('tests', $testResultList.Count)
    $xmlWriter.WriteAttributeString('time', $testTimerSeconds)
    $xmlWriter.WriteAttributeString('failures', $numberOfFailed)

    $xmlWriter.WriteStartElement('testsuite')
    $xmlWriter.WriteAttributeString('tests', $testResultList.Count)
    $xmlWriter.WriteAttributeString('timestamp', (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"))

    $totalNumber = $testResultList.Count
    $iterator = 1
    $procentageCompleteOld = 0
    $lastWrittenProcentage = 0

    foreach ($result in $testResultList){
        $testName = $result.TestName
        $className = $hostname
        if ($true -ne $result.Error) {
            $xmlWriter.WriteStartElement('testcase')
            $xmlWriter.WriteAttributeString('classname', $className)
            $xmlWriter.WriteAttributeString('name', $testName)
            $xmlWriter.WriteAttributeString('time', $result.Time)
            $xmlWriter.WriteEndElement() #/testcase
        }
        else #if ($result.Result -eq 2) 
        {
            $xmlWriter.WriteStartElement('testcase')
            $xmlWriter.WriteAttributeString('classname', $className)
            $xmlWriter.WriteAttributeString('name', $testName)
            $xmlWriter.WriteAttributeString('time', $result.Time)
                $xmlWriter.WriteStartElement('failure')
                #$xmlWriter.WriteAttributeString('type', $result.HttpStatus)
                $xmlWriter.WriteString($result.Description)
                $xmlWriter.WriteEndElement() #/failure
            $xmlWriter.WriteEndElement() #/testcase
        }

        $procentageComplete = [math]::Truncate(($iterator / $totalNumber) * 100)
        if ($procentageComplete -ne $procentageCompleteOld){
            Write-Progress -Activity "Write test result XML" -Status "$procentageComplete% Complete:" -PercentComplete $procentageComplete;
            $procentageCompleteOld = $procentageComplete
        }
        if (($procentageComplete % 10) -eq 0 -and $lastWrittenProcentage -ne $procentageComplete){
            Write-Host "Write test result XML: $procentageComplete% Complete."
            $lastWrittenProcentage = $procentageComplete
        }
        $iterator++;
    }

    $xmlWriter.WriteEndElement() #/testsuite
    $xmlWriter.WriteEndElement() #/testsuites

    $xmlWriter.WriteEndDocument()
    $xmlWriter.Flush()
    $xmlWriter.Close()

    # <testsuites name='my-test-suite' tests='3' time='0.3' failures='1'>
    #     <testsuite tests='3' timestamp='2020-05-14T12:35:00'>
    #         <testcase classname='foo1' name='ASuccessfulTest' time='0.1'/>
    #         <testcase classname='foo2' name='AnotherSuccessfulTest' time='0.1'/>
    #         <testcase classname='foo3' name='AFailingTest' time='0.1'>
    #             <failure type='NotEnoughFoo'> details about failure </failure>
    #         </testcase>
    #     </testsuite>
    # </testsuites>

}


# enum ResultType {
#     unknown
#     Success = 2
#     Warning = 1
#     Failed = 0
#     NotTested = -1
# }

# class TestResult {
#     [ResultType]$Result
#     [string]$Url
#     [string]$Time
#     [int]$HttpStatus
#     [string]$Description
#     [object]$RequestHeader
# }

# function Get-UrlStatus {
#     <#
#     .SYNOPSIS
#         Make a GET request and return the status of the response.

#     .DESCRIPTION
#         Make a GET request and return the status of the response.

#     .PARAMETER Url
#         The URL that will be requested.

#     .PARAMETER DefaultHeader
#         The header that will be sent with the request.

#     .EXAMPLE
#         Get-UrlStatus -Url $Url -DefaultHeader $DefaultHeader

#     .EXAMPLE
#         Get-UrlStatus -Url "https://customer.se" -DefaultHeader @{"User-Agent"="CheckWebsite"}

#     #>    
#     [CmdletBinding()]
#     [OutputType([UrlResult])]
#     param(
#         [Parameter(Mandatory = $true)]
#         [string] $Url,

#         [Parameter(Mandatory = $false)]
#         [object] $DefaultHeader
#     )

#     $swUrl = [Diagnostics.Stopwatch]::StartNew()
#     $swUrl.Start()

#     try {
#         if ([string]::IsNullOrEmpty($defaultHeader)) {
#             $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -Verbose:$false -MaximumRedirection 2
#         } else {
#             $response = Invoke-WebRequest -Uri $url -Headers $defaultHeader -UseBasicParsing -Verbose:$false -MaximumRedirection 2
#         }
#         $swUrl.Stop()
#         $statusCode = $response.StatusCode
#         $seconds = $swUrl.Elapsed.TotalSeconds
#         if ($statusCode -eq 200) {
#             $statusDescription = $response.StatusDescription
#             Write-Host "$Url => Status: $statusCode $statusDescription in $seconds seconds" -ForegroundColor Black -BackgroundColor Green
#         }
#       }
#       catch {
#             $swUrl.Stop()
#             $_.Exception
#             #$statusCode = 500
#             $statusCode = $_.Exception.Response.StatusCode.value__
#             $errorMessage = $_.Exception.Message
#             $seconds = $swUrl.Elapsed.TotalSeconds
#             if ($statusCode -eq 500) {
#                 Write-Host "$Url => Error $statusCode after $seconds seconds: $errorMessage" -BackgroundColor Red
#             }
#             elseif ($statusCode -eq 301) {
#                 Write-Host "$Url => Error $statusCode after $seconds seconds: $errorMessage" -ForegroundColor Black -BackgroundColor Yellow
#                 $response
#             }
#             else {
#                 Write-Host "$Url => Error $statusCode after $seconds seconds: $errorMessage" -ForegroundColor Black -BackgroundColor Yellow
#             }
#       }
#       return $statusCode
# }

# function CheckUrl {
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true)]
#         [object] $requestSpec,

#         [Parameter(Mandatory = $true)]
#         [bool] $hide200result
#     )
#     $swUrl = [Diagnostics.Stopwatch]::StartNew()
#     $swUrl.Start()
#     try {
#         $requestHeaders = $requestSpec[1]
#         $requestUrl = $requestSpec[0]
#           if ([string]::IsNullOrEmpty($requestHeaders)) {
#               $response = Invoke-WebRequest -Uri $requestUrl -UseBasicParsing -Verbose:$false -MaximumRedirection 1
#           } else {
#               $response = Invoke-WebRequest -Uri $requestUrl -Headers $requestHeaders -UseBasicParsing -Verbose:$false -MaximumRedirection 1
#           }
#           $swUrl.Stop()
#           $statusCode = $response.StatusCode
#           $seconds = $swUrl.Elapsed.TotalSeconds
#           if ($statusCode -eq 200) {
#             if ($hide200result -ne $true){
#                 $statusDescription = $response.StatusDescription
#                 Write-Host "$requestUrl => Status: $statusCode $statusDescription in $seconds seconds" -ForegroundColor Black -BackgroundColor Green
#               }
#           } else {
#               Write-Warning "$requestUrl => Error $statusCode after $seconds seconds"
#           }
#       }
#       catch {
#           $swUrl.Stop()
#           $statusCode = $_.Exception.Response.StatusCode.value__
#           $errorMessage = $_.Exception.Message
#           $seconds = $swUrl.Elapsed.TotalSeconds
#           if ($statusCode -eq 500) {
#             Write-Host "$requestUrl => Error $statusCode after $seconds seconds: $errorMessage" -BackgroundColor Red
#           }
#           else {
#             Write-Host "$requestUrl => Error $statusCode after $seconds seconds: $errorMessage" -ForegroundColor Black -BackgroundColor Yellow
#           }
#       }
#       return $statusCode
# }

# function CheckTestResultUrl {
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true)]
#         [object] $testResult
#     )
#     $swUrl = [Diagnostics.Stopwatch]::StartNew()
#     $swUrl.Start()
#     try {
#         #$requestHeaders = $requestSpec[1]
#         #$requestUrl = $requestSpec[0]
#         $requestHeaders = $testResult.RequestHeader
#         $requestUrl = $testResult.Url
#         if ([string]::IsNullOrEmpty($requestHeaders)) {
#             $response = Invoke-WebRequest -Uri $requestUrl -UseBasicParsing -Verbose:$false -MaximumRedirection 1
#         } else {
#             $response = Invoke-WebRequest -Uri $requestUrl -Headers $requestHeaders -UseBasicParsing -Verbose:$false -MaximumRedirection 1
#         }
#         $swUrl.Stop()
#         $statusCode = $response.StatusCode
#         $seconds = $swUrl.Elapsed.TotalSeconds
#         $testResult.Time = $seconds
#         $testResult.HttpStatus = $statusCode
#         if ($statusCode -eq 200) {
#             $testResult.Result = 2
#             $testResult.Description = "200"
#         } else {
#             $testResult.Result = 1
#             $testResult.Description = $response.StatusDescription
#         }
#     }
#     catch {
#         $swUrl.Stop()
#         $statusCode = $_.Exception.Response.StatusCode.value__
#         $errorMessage = $_.Exception.Message
#         $seconds = $swUrl.Elapsed.TotalSeconds
#         $testResult.HttpStatus = $statusCode
#         $testResult.Time = $seconds
#         if ($statusCode -eq 500) {
#             $testResult.Result = 0
#             $testResult.Description = $errorMessage
#             #Write-Host "$requestUrl => Error $statusCode after $seconds seconds: $errorMessage" -BackgroundColor Red
#         }
#         else {
#             $testResult.Result = 1
#             $testResult.Description = $errorMessage
#             #Write-Host "$requestUrl => Error $statusCode after $seconds seconds: $errorMessage" -ForegroundColor Black -BackgroundColor Yellow
#         }
#     }
#     return $testResult
# }

# function LoopUrlset{
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true)]
#         [object] $urlset
#     )
#     foreach($urlElement in $urlset.url){
#         $locUrl = $urlElement.loc
#         $requestSpec = @($locUrl, $defaultHeader)
#         CheckUrl -requestSpec $requestSpec -hide200result $hide200result
#         #Start-Sleep 2
#     }
# }

# function RobotsPolishUrl{
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true)]
#         [string] $siteurl
#     )
#     if ($siteurl.EndsWith("/robots.txt") -eq $false){
#         if ($siteurl.EndsWith("/") -eq $false)
#         {
#             $siteurl = $siteurl + "/robots.txt"
#         }
#         else
#         {
#             $siteurl = $siteurl + "robots.txt"
#         }
#     }
#     Write-Host "Robots.txt url: $siteurl"
#     return $siteurl
# }

# function GetSitemapUrlFromRobotsTxt{
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true)]
#         [string] $robotsTxtUrl
#     )
#     # Download the content from the robots.txt
#     $robotsTxtContent = (New-Object System.Net.WebClient).DownloadString($robotsTxtUrl)

#     #Write-Host "Robots.txt content: |$robotsTxtContent|"
#     if ($robotsTxtContent.Contains('Sitemap:') -eq $true -or $robotsTxtContent.Contains('sitemap:') -eq $true)
#     {
#         $robotsTxtContent = "`n" + $robotsTxtContent
#         #Write-Host "Robots.txt content: |$robotsTxtContent|"
#         #$something = $text | Select-String -Pattern 'Sitemap: (.*)$'
#         try{
#             #Write-Host [regex]::Match($robotsTxtContent, "[S|s]itemap: (.*)$").Success
#             $sitemapLink = [regex]::Match($robotsTxtContent, "[S|s]itemap: (.*)$").captures.groups[1].value
#             Write-Host "GetSitemapUrlFromRobotsTxt regex found: $sitemapLink"
#         }catch {}
#         #if ($null -eq $sitemapLink) { Write-Host "Could not find Sitemap reference in robots.txt with regex" -BackgroundColor Red -ForegroundColor White }
#     }
#     if ($null -eq $sitemapLink) { Write-Host "Could not find Sitemap reference in robots.txt with regex" -BackgroundColor Black -ForegroundColor Red }
#     return $sitemapLink
# }

# function CreateTestResultCollectionOfSitemap{
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true)]
#         [string] $sitemapLink
#     )

#     $list = New-Object 'System.Collections.Generic.List[TestResult]'

#     if ($null -ne $sitemapLink)
#     {
#         [xml]$XmlDocument = (New-Object System.Net.WebClient).DownloadString($sitemapLink)
#         $urlset = $XmlDocument.urlset

#         #check if the sitemap is a sitemapindex or not
#         if ($null -eq $urlset)
#         {
#             $sitemapIndex = $XmlDocument.sitemapindex
#             foreach ($sitemap in $sitemapIndex.sitemap)
#             {
#                 [xml]$sitemapXmlDoc = (New-Object System.Net.WebClient).DownloadString($sitemap.loc)
#                 #LoopUrlset -urlset $sitemapXmlDoc.urlset
#                 foreach($urlElement in $sitemapXmlDoc.urlset.url){
#                     $locUrl = $urlElement.loc
#                     #$requestSpec = @($locUrl, $defaultHeader)
#                     #CheckUrl -requestSpec $requestSpec -hide200result $hide200result
#                     #Start-Sleep 2
#                     #Write-Host "Loc: $locUrl"
#                     $testResultLoc = [TestResult]::New();
#                     $testResultLoc.Result = -1
#                     $testResultLoc.Url = $locUrl
#                     $list.Add($testResultLoc)
#                 }
#             }
#         }
#         else
#         {
#             #$urlset
#             #LoopUrlset -urlset $XmlDocument.urlset
#             foreach($urlElement in $urlset.url){
#                 #$urlElement
#                 $locUrl = $urlElement.loc
#                 #$requestSpec = @($locUrl, $defaultHeader)
#                 #CheckUrl -requestSpec $requestSpec -hide200result $hide200result
#                 #Start-Sleep 2
#                 #Write-Host "Loc: $locUrl"
#                 $testResultLoc = [TestResult]::New();
#                 $testResultLoc.Result = -1
#                 $testResultLoc.Url = $locUrl
#                 $list.Add($testResultLoc)
#             }
#         }
#     }
#     return $list
# }

# function TestTestResultCollection{
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true)]
#         [object] $testResultCollection
#     )
#     $totalNumber = $testResultCollection.Count
#     $iterator = 1
#     $procentageCompleteOld = 0
#     foreach ($result in $testResultList){
#         #$result
#         # $requestSpec = @($result.Url, $defaultHeader)
#         # $testStatus = CheckUrl -requestSpec $requestSpec -hide200result $hide200result
#         # if ($testStatus -eq 200)
#         # {
#         #     $result.Result = 2
#         # }
#         # elseif ($testStatus -eq 301) {
#         #     $result.Result = 1
#         # }
#         # else {
#         #     $result.Result = 0
#         # }
#         $result = CheckTestResultUrl -testResult $result

#         $procentageComplete = [math]::Truncate(($iterator / $totalNumber) * 100)
#         if ($procentageComplete -ne $procentageCompleteOld){
#             Write-Progress -Activity "Test URLs" -Status "$procentageComplete% Complete:" -PercentComplete $procentageComplete;
#             $procentageCompleteOld = $procentageComplete
#         }
#         if (($procentageComplete % 10) -eq 0){
#             Write-Host "Test URLs: $procentageComplete% Complete."
#         }
#         $iterator++;
#    }
# }

# function PrintTestResultXml{
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true)]
#         [string] $testResultFileName,
#         [Parameter(Mandatory = $true)]
#         [object] $testResultList,
#         [Parameter(Mandatory = $true)]
#         [string] $baseUrl,
#         [Parameter(Mandatory = $true)]
#         [long] $testTimerSeconds,
#         [Parameter(Mandatory = $false)]
#         [string] $filePath
#     )

#     $errorResults = $testResultList | Where-Object {$_.Result -eq 0}

#     $uri = [System.Uri]$baseUrl
#     $hostname = $uri.IdnHost

#     if ($null -ne $filePath -and $filePath.Length -ne 0 -and $filePath.EndsWith('\') -ne $true){
#         $filePath = $filePath + "\"
#     }
#     if ($testResultFileName.Contains("€hostname") -eq $false){
#         Write-Error "Param testResultFileName does not contains €hostname."
#     }
#     if ($testResultFileName.Contains("€dateTime") -eq $false){
#         Write-Error "Param testResultFileName does not contains €dateTime."
#     }

#     $dateTime = Get-Date -Format "yyyyMMddTHHmmss"
#     $testResultFileName = $testResultFileName -replace "€hostname", $hostname
#     $testResultFileName = $testResultFileName -replace "€dateTime", $dateTime

#     $fileName = $filePath + $testResultFileName
#     Write-Host "Create result file: $fileName"
#     $xmlWriter = New-Object System.XMl.XmlTextWriter($fileName,$Null)
#     $xmlWriter.Formatting = 'Indented'
#     $xmlWriter.Indentation = 1
#     $XmlWriter.IndentChar = "`t"
#     $xmlWriter.WriteStartDocument()

#     $xmlWriter.WriteStartElement('testsuites')
#     $XmlWriter.WriteAttributeString('name', 'check-website-test-suite')
#     $XmlWriter.WriteAttributeString('tests', $testResultList.Count)
#     $XmlWriter.WriteAttributeString('time', $testTimerSeconds)
#     $XmlWriter.WriteAttributeString('failures', $errorResults.Count)

#     $xmlWriter.WriteStartElement('testsuite')
#     $XmlWriter.WriteAttributeString('tests', $testResultList.Count)
#     $XmlWriter.WriteAttributeString('timestamp', (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"))

#     $totalNumber = $testResultList.Count
#     $iterator = 1
#     $procentageCompleteOld = 0

#     foreach ($result in $testResultList){
#         $resultUrl = $result.Url
#         $className = $hostname
#         if ($result.Result -eq 0 -or $result.Result -eq 1) {
#             $xmlWriter.WriteStartElement('testcase')
#             $XmlWriter.WriteAttributeString('classname', $className)
#             $XmlWriter.WriteAttributeString('name', $resultUrl)
#             $XmlWriter.WriteAttributeString('time', $result.Time)
#                 $xmlWriter.WriteStartElement('failure')
#                 $XmlWriter.WriteAttributeString('type', $result.HttpStatus)
#                 $XmlWriter.WriteString($result.Description)
#                 $xmlWriter.WriteEndElement() #/failure
#             $xmlWriter.WriteEndElement() #/testcase
#         }
#         elseif ($result.Result -eq 2) {
#             $xmlWriter.WriteStartElement('testcase')
#             $XmlWriter.WriteAttributeString('classname', $className)
#             $XmlWriter.WriteAttributeString('name', $resultUrl)
#             $XmlWriter.WriteAttributeString('time', $result.Time)
#             $xmlWriter.WriteEndElement() #/testcase
#         }

#         $procentageComplete = [math]::Truncate(($iterator / $totalNumber) * 100)
#         if ($procentageComplete -ne $procentageCompleteOld){
#             Write-Progress -Activity "Write test result XML" -Status "$procentageComplete% Complete:" -PercentComplete $procentageComplete;
#             $procentageCompleteOld = $procentageComplete
#         }
#         if (($procentageComplete % 10) -eq 0){
#             Write-Host "Write test result XML: $procentageComplete% Complete."
#         }
#         $iterator++;
#     }

#     $xmlWriter.WriteEndElement() #/testsuite
#     $xmlWriter.WriteEndElement() #/testsuites

#     $xmlWriter.WriteEndDocument()
#     $xmlWriter.Flush()
#     $xmlWriter.Close()

#     # <testsuites name='my-test-suite' tests='3' time='0.3' failures='1'>
#     #     <testsuite tests='3' timestamp='2020-05-14T12:35:00'>
#     #         <testcase classname='foo1' name='ASuccessfulTest' time='0.1'/>
#     #         <testcase classname='foo2' name='AnotherSuccessfulTest' time='0.1'/>
#     #         <testcase classname='foo3' name='AFailingTest' time='0.1'>
#     #             <failure type='NotEnoughFoo'> details about failure </failure>
#     #         </testcase>
#     #     </testsuite>
#     # </testsuites>

# }
