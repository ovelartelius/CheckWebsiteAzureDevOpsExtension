Trace-VstsEnteringInvocation $MyInvocation
$global:ErrorActionPreference = 'Continue'
$global:__vstsNoOverrideVerbose = $true

try {
    # Get all inputs for the task
    $siteUrl = Get-VstsInput -Name "SiteUrl" -Require -ErrorAction "Stop"
    $resultFilePath = Get-VstsInput -Name "ResultFilePath" -Require -ErrorAction "Stop"
    $userAgent = Get-VstsInput -Name "UserAgent"

    ####################################################################################

    Write-Host "Inputs:-----------------------------"
    Write-Host "SiteUrl:            $siteUrl"
    Write-Host "Result file path:   $resultFilePath"
    Write-Host "UserAgent:          $userAgent"
    Write-Host "------------------------------------"
    
    
    if ($null -eq $userAgent -or $userAgent.Length -eq 0){
        $userAgent = "CheckWebsite"
    }
    
    # Load spider
    [Reflection.Assembly]::LoadFile("$PSScriptRoot\Spider.dll")
    $spider = new-object Spider.Spider
    
    # Validate the site URL
    $validUrl = $spider.ValidateUrl($siteUrl)
    if ($false -eq $validUrl) {
        Write-Error "Provided URL $siteUrl is not a valid URI."
        return 1
    }
    
    # Test connection to the site.
    try {
        $siteUrlResult = $spider.PsCheckUrl($siteUrl, $userAgent)
    } catch {
        if ($siteUrl.StartsWith("http://")){
            $siteUrl = $siteUrl.Replace("http://", "https://")
            $siteUrlResult = $spider.PsCheckUrl($siteUrl, $userAgent)
        }
    }
    
    
    #$siteHostStatus
    # Write-Host "Host status: $siteHostStatus"
    if ($siteUrlResult.StatusCode -ne 200)
    {
        Write-Error "Failed to connect to $siteUrl get HttpStatus $($siteUrlResult.StatusCode)"
        Write-Host "##vso[task.logissue type=error]Failed to connect to $siteUrl get HttpStatus $($siteUrlResult.StatusCode)"
        return 1
    }
    
    $robotsTxtUrl = ""
    if ($true -eq $siteUrlResult.IsSiteDomain) {
        # We need to pimp the url and get the robots.txt
        $robotsTxtUrl = $spider.CreateRobotsTxtUrl($siteUrl)
        #Write-Host "IsSiteDomain"
    } elseif ($true -eq $siteUrlResult.IsRobotsTxt) {
        $robotsTxtUrl = $siteUrlResult.Url
        #Write-Host "IsRobotsTxt"
    }
    
    $sitemapLink = ""
    if ($true -eq $siteUrlResult.IsSitemapXml){
        $sitemapLink = $siteUrlResult.Url
        #Write-Host "IsSitemapXml"
    } elseif ($robotsTxtUrl.Length -ne 0){
        # Load the robots txt.
        $sitemapLink = [Spider.Sitemap]::GetSitemapUrlFromRobotsTxt($robotsTxtUrl)
    } 
    
    if ($null -eq $sitemapLink -or $sitemapLink.Length -eq 0){
        Write-Host "Could not find Sitemap reference in robots.txt with regex" -BackgroundColor Black -ForegroundColor Red
        exit
        return 1
    } else {
        Write-Host "Sitemap: $sitemapLink"
    }
    
    $sitemapUrls = [Spider.Sitemap]::GetSitemapUrls($sitemapLink)
    #$sitemapUrls
    
    $testResultArray = [System.Collections.ArrayList]::new()
    
    $totalNumber = $sitemapUrls.Count
    $iterator = 1
    $procentageCompleteOld = 0
    $testTimer = [Diagnostics.Stopwatch]::StartNew()
    $testTimer.Start()
    $lastWrittenProcentage = 0
    foreach ($testUrl in $sitemapUrls){
        $testUrlResult = $spider.PsCheckUrl($testUrl, $userAgent)
        Write-Verbose "$($testUrlResult.Url) - $($testUrlResult.StatusCode)"
        [void]$testResultArray.Add($testUrlResult)
    
        $procentageComplete = [math]::Truncate(($iterator / $totalNumber) * 100)
        if ($procentageComplete -ne $procentageCompleteOld){
            Write-Progress -Activity "Test URLs" -Status "$procentageComplete% Complete:" -PercentComplete $procentageComplete;
            $procentageCompleteOld = $procentageComplete
        }
        if (($procentageComplete % 10) -eq 0 -and $lastWrittenProcentage -ne $procentageComplete){
            Write-Host "Test URLs: $procentageComplete% Complete."
            $lastWrittenProcentage = $procentageComplete
        }
        $iterator++;
    }
    
    . "$PSScriptRoot\LolCheckWebsiteUtil.ps1"
    
    $testTimer.Stop()
    $testTimerSeconds = $testTimer.Elapsed.TotalSeconds
    
    $testResultFileName = "TEST-CheckSitemap_€hostname_result_€dateTime.xml"
    PrintSitemapTestResultXml -testResultFileName $testResultFileName -testResultList $testResultArray -baseUrl $siteUrl -testTimerSeconds $testTimerSeconds -filePath $resultFilePath
    
    # Write-Host "Inputs:"
    # Write-Host "SiteUrl: $siteUrl"
    # Write-Host "Result file path: $resultFilePath"
    
    # if ($null -ne $userAgent -and $userAgent.Length -ne 0){
    #     $defaultHeader = @{"User-Agent"="$userAgent"}
    # }
    # else{
    #     $defaultHeader = @{"User-Agent"="CheckWebsite"}
    # }
    
    
    # [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # . "$PSScriptRoot\LolCheckWebsiteUtil.ps1"
    
    # $testTimer = [Diagnostics.Stopwatch]::StartNew()
    # $testTimer.Start()
    
    # $siteHostStatus = Get-UrlStatus -url $siteUrl -defaultHeader $defaultHeader
    # Write-Host "Host status: $siteHostStatus"
    # if ($siteHostStatus -ne 200)
    # {
    #     Write-Error "Failed to connect to $siteUrl get HttpStatus $siteHostStatus"
    #     Write-Host "##vso[task.logissue type=error]Failed to connect to $siteUrl get HttpStatus $siteHostStatus"
    #     return 1
    # }
    
    # $robotsUrl = RobotsPolishUrl -siteurl $siteUrl
    # $siteRobotsTxtStatus = Get-UrlStatus -url $robotsUrl -defaultHeader $defaultHeader
    # Write-Host "Robots.txt status: $siteRobotsTxtStatus"
    # if ($siteRobotsTxtStatus -ne 200)
    # {
    #     Write-Error "Failed to connect to $robotsUrl get HttpStatus $siteRobotsTxtStatus"
    #     Write-Host "##vso[task.logissue type=error]Failed to connect to $robotsUrl get HttpStatus $siteRobotsTxtStatus"
    #     return 1
    # }
    
    # $sitemapUrl = GetSitemapUrlFromRobotsTxt -robotsTxtUrl $robotsUrl -defaultHeader $defaultHeader
    # Write-Host "Sitemap.xml url: $sitemapUrl"
    # $sitemapStatus = Get-UrlStatus -url $sitemapUrl
    # Write-Host "Sitemap.xml status: $sitemapStatus"
    # if ($sitemapStatus -ne 200)
    # {
    #     Write-Error "Failed to connect to $sitemapUrl get HttpStatus $sitemapStatus"
    #     Write-Host "##vso[task.logissue type=error]Failed to connect to $sitemapUrl get HttpStatus $sitemapStatus"
    #     return 1
    # }
    
    # $testResultList = CreateTestResultCollectionOfSitemap -sitemapLink $sitemapUrl
    
    # TestTestResultCollection -testResultCollection $testResultList
    
    # $testTimer.Stop()
    
    # $testTimerSeconds = $testTimer.Elapsed.TotalSeconds
    # $testResultFileName = "TEST-CheckSitemap_€hostname_result_€dateTime.xml"
    # PrintTestResultXml -testResultFileName $testResultFileName -testResultList $testResultList -baseUrl $siteUrl -testTimerSeconds $testTimerSeconds -filePath $resultFilePath
    
    ####################################################################################

    Write-Host "---THE END---"

}
catch {
    Write-Verbose "Exception caught from task: $($_.Exception.ToString())"
    throw
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}

