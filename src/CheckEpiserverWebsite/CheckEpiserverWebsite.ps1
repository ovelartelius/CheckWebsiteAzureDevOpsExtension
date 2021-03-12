Trace-VstsEnteringInvocation $MyInvocation
$global:ErrorActionPreference = 'Continue'
$global:__vstsNoOverrideVerbose = $true

try {
    # Get all inputs for the task
    $siteUrl = Get-VstsInput -Name "SiteUrl" -Require -ErrorAction "Stop"
    $resultFilePath = Get-VstsInput -Name "ResultFilePath" -Require -ErrorAction "Stop"
    $userAgent = Get-VstsInput -Name "UserAgent"
    $checkLicense = Get-VstsInput -Name "CheckLicense" -AsBool
    $checkRobotsTxt = Get-VstsInput -Name "CheckRobotsTxt" -AsBool

    ####################################################################################

    Write-Host "Inputs:-----------------------------"
    Write-Host "SiteUrl:            $siteUrl"
    Write-Host "Result file path:   $resultFilePath"
    Write-Host "UserAgent:          $userAgent"
    Write-Host "Tests:------------------------------"
    Write-Host "CheckLicense:       $checkLicense"
    Write-Host "CheckRobotsTxt:     $checkRobotsTxt"
    Write-Host "------------------------------------"
    
    . "$PSScriptRoot\LolCheckWebsiteUtil.ps1"
    
    if ($null -eq $userAgent -or $userAgent.Length -eq 0){
        $userAgent = "CheckWebsite"
    }

    $list = New-Object 'System.Collections.Generic.List[TestResult]'

    $totalStopwatch = [Diagnostics.Stopwatch]::StartNew()
    $totalStopwatch.Start()

    # Load spider
    [Reflection.Assembly]::LoadFile("$PSScriptRoot\Spider.dll")
    $spider = new-object Spider.Spider
    
    # Validate the site URL
    #-------------------------------------------------------
    $testStopwatch = [Diagnostics.Stopwatch]::StartNew()
    $testStopwatch.Start()
    $testResult = [TestResult]::New();
    $testResult.TestName = "Validate site URL"
    $validUrl = $spider.ValidateUrl($siteUrl)
    if ($false -eq $validUrl) {
        $testErrorDescription = "Provided URL $siteUrl is not a valid URI."
        Write-Wrning $testErrorDescription
        $testResult.Error = $true
        $testResult.Description = $testErrorDescription
    } else {
        $testResult.Error = $false
    }
    $testStopwatch.Stop()
    $testResult.Time = $testStopwatch.Elapsed.TotalSeconds
    $list.Add($testResult)
    #-------------------------------------------------------


    $totalStopwatch.Stop()
    $testTimerSeconds = $totalStopwatch.Elapsed.TotalSeconds
    
    $testResultFileName = "TEST-CheckEpiserverSitemap_€hostname_result_€dateTime.xml"
    PrintGenericTestResultXml -testResultFileName $testResultFileName -testResultList $list -baseUrl $siteUrl -testTimerSeconds $testTimerSeconds -filePath $resultFilePath

    
    # # Test connection to the site.
    # try {
    #     $siteUrlResult = $spider.PsCheckUrl($siteUrl, $userAgent)
    # } catch {
    #     if ($siteUrl.StartsWith("http://")){
    #         $siteUrl = $siteUrl.Replace("http://", "https://")
    #         $siteUrlResult = $spider.PsCheckUrl($siteUrl, $userAgent)
    #     }
    # }
    
    
    # #$siteHostStatus
    # # Write-Host "Host status: $siteHostStatus"
    # if ($siteUrlResult.StatusCode -ne 200)
    # {
    #     Write-Error "Failed to connect to $siteUrl get HttpStatus $($siteUrlResult.StatusCode)"
    #     Write-Host "##vso[task.logissue type=error]Failed to connect to $siteUrl get HttpStatus $($siteUrlResult.StatusCode)"
    #     return 1
    # }
    
    # $robotsTxtUrl = ""
    # if ($true -eq $siteUrlResult.IsSiteDomain) {
    #     # We need to pimp the url and get the robots.txt
    #     $robotsTxtUrl = $spider.CreateRobotsTxtUrl($siteUrl)
    #     #Write-Host "IsSiteDomain"
    # } elseif ($true -eq $siteUrlResult.IsRobotsTxt) {
    #     $robotsTxtUrl = $siteUrlResult.Url
    #     #Write-Host "IsRobotsTxt"
    # }
    
    # $sitemapLink = ""
    # if ($true -eq $siteUrlResult.IsSitemapXml){
    #     $sitemapLink = $siteUrlResult.Url
    #     #Write-Host "IsSitemapXml"
    # } elseif ($robotsTxtUrl.Length -ne 0){
    #     # Load the robots txt.
    #     $sitemapLink = [Spider.Sitemap]::GetSitemapUrlFromRobotsTxt($robotsTxtUrl)
    # } 
    
    # if ($null -eq $sitemapLink -or $sitemapLink.Length -eq 0){
    #     Write-Host "Could not find Sitemap reference in robots.txt with regex" -BackgroundColor Black -ForegroundColor Red
    #     exit
    #     return 1
    # } else {
    #     Write-Host "Sitemap: $sitemapLink"
    # }
    
    # $sitemapUrls = [Spider.Sitemap]::GetSitemapUrls($sitemapLink)
    # #$sitemapUrls
    
    # $testResultArray = [System.Collections.ArrayList]::new()
    
    # $totalNumber = $sitemapUrls.Count
    # $iterator = 1
    # $procentageCompleteOld = 0
    # $testTimer = [Diagnostics.Stopwatch]::StartNew()
    # $testTimer.Start()
    # $lastWrittenProcentage = 0
    # foreach ($testUrl in $sitemapUrls){
    #     try {
    #         $testUrlResult = $spider.PsCheckUrl($testUrl, $userAgent)
    #         Write-Verbose "$($testUrlResult.Url) - $($testUrlResult.StatusCode)"
    #         [void]$testResultArray.Add($testUrlResult)
    #     } catch {
    #         Write-Warning "Could not handle $testUrl"
    #     }
    
    #     $procentageComplete = [math]::Truncate(($iterator / $totalNumber) * 100)
    #     if ($procentageComplete -ne $procentageCompleteOld){
    #         Write-Progress -Activity "Test URLs" -Status "$procentageComplete% Complete:" -PercentComplete $procentageComplete;
    #         $procentageCompleteOld = $procentageComplete
    #     }
    #     if (($procentageComplete % 10) -eq 0 -and $lastWrittenProcentage -ne $procentageComplete){
    #         Write-Host "Test URLs: $procentageComplete% Complete."
    #         $lastWrittenProcentage = $procentageComplete
    #     }
    #     $iterator++;
    # }
    
    # . "$PSScriptRoot\LolCheckWebsiteUtil.ps1"
    
    # $testTimer.Stop()
    # $testTimerSeconds = $testTimer.Elapsed.TotalSeconds
    
    # $testResultFileName = "TEST-CheckSitemap_€hostname_result_€dateTime.xml"
    # PrintSitemapTestResultXml -testResultFileName $testResultFileName -testResultList $testResultArray -baseUrl $siteUrl -testTimerSeconds $testTimerSeconds -filePath $resultFilePath

    
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

