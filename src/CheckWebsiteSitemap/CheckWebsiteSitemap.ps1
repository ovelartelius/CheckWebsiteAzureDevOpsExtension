Trace-VstsEnteringInvocation $MyInvocation
$global:ErrorActionPreference = 'Continue'
$global:__vstsNoOverrideVerbose = $true

try {
    # Get all inputs for the task
    $siteUrl = Get-VstsInput -Name "SiteUrl" -Require -ErrorAction "Stop"
    $resultFilePath = Get-VstsInput -Name "ResultFilePath" -Require -ErrorAction "Stop"
    $userAgent = Get-VstsInput -Name "UserAgent"

    ####################################################################################


    Write-Host "Inputs:"
    Write-Host "SiteUrl: $siteUrl"
    Write-Host "Result file path: $resultFilePath"
    
    if ($null -ne $userAgent -and $userAgent.Length -ne 0){
        $defaultHeader = @{"User-Agent"="$userAgent"}
    }
    else{
        $defaultHeader = @{"User-Agent"="SpaceSpider"}
    }
    
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    . "$PSScriptRoot\CheckUrlFunctions.ps1"
    
    
    $testTimer = [Diagnostics.Stopwatch]::StartNew()
    $testTimer.Start()
    
    $siteHostStatus = GetUrlStatus -url $siteUrl -defaultHeader $defaultHeader
    Write-Host "Host status: $siteHostStatus"
    if ($siteHostStatus -ne 200)
    {
        Write-Error "Failed to connect to $siteUrl get HttpStatus $siteHostStatus"
        Write-Host "##vso[task.logissue type=error]Failed to connect to $siteUrl get HttpStatus $siteHostStatus"
        return 1
    }
    
    $robotsUrl = RobotsPolishUrl -siteurl $siteUrl
    $siteRobotsTxtStatus = GetUrlStatus -url $robotsUrl -defaultHeader $defaultHeader
    Write-Host "Robots.txt status: $siteRobotsTxtStatus"
    if ($siteRobotsTxtStatus -ne 200)
    {
        Write-Error "Failed to connect to $robotsUrl get HttpStatus $siteRobotsTxtStatus"
        Write-Host "##vso[task.logissue type=error]Failed to connect to $robotsUrl get HttpStatus $siteRobotsTxtStatus"
        return 1
    }
    
    $sitemapUrl = GetSitemapUrlFromRobotsTxt -robotsTxtUrl $robotsUrl -defaultHeader $defaultHeader
    Write-Host "Sitemap.xml url: $sitemapUrl"
    $sitemapStatus = GetUrlStatus -url $sitemapUrl
    Write-Host "Sitemap.xml status: $sitemapStatus"
    if ($sitemapStatus -ne 200)
    {
        Write-Error "Failed to connect to $sitemapUrl get HttpStatus $sitemapStatus"
        Write-Host "##vso[task.logissue type=error]Failed to connect to $sitemapUrl get HttpStatus $sitemapStatus"
        return 1
    }
    
    $testResultList = CreateTestResultCollectionOfSitemap -sitemapLink $sitemapUrl
    
    TestTestResultCollection -testResultCollection $testResultList
    
    $testTimer.Stop()
    
    $testTimerSeconds = $testTimer.Elapsed.TotalSeconds
    $testResultFileName = "TEST-CheckSitemap_€hostname_result_€dateTime.xml"
    PrintTestResultXml -testResultFileName $testResultFileName -testResultList $testResultList -baseUrl $siteUrl -testTimerSeconds $testTimerSeconds -filePath $resultFilePath
    
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

