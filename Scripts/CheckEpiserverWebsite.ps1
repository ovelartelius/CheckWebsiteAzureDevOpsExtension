Set-StrictMode -Version Latest
. E:\dev\CheckWebsiteAzureDevOpsExtension\Modules\LolCheckWebsiteUtil.ps1

[Reflection.Assembly]::LoadFile("E:\dev\CheckWebsiteAzureDevOpsExtension\Modules\Spider.dll")

$siteUrl = "http://mobelstudion.se"
$resultFilePath = ""
$userAgent = ""
$checkLicense = $true
$checkRobotsTxt = $true
Write-Host "Inputs:-----------------------------"
Write-Host "SiteUrl:            $siteUrl"
Write-Host "Result file path:   $resultFilePath"
Write-Host "UserAgent:          $userAgent"
Write-Host "Tests:------------------------------"
Write-Host "CheckLicense:       $checkLicense"
Write-Host "CheckRobotsTxt:     $checkRobotsTxt"
Write-Host "------------------------------------"

# $spider = new-object Spider.Spider

# $siteUrl = "https://seb.no/"

# # Validate the site URL
# $validUrl = $spider.ValidateUrl($siteUrl)
# if ($false -eq $validUrl) {
#     Write-Error "Provided URL $siteUrl is not a valid URI."
#     return 1
# }

# # Test connection to the site.
# $validUrl = $spider.ValidateUrlOnSite($siteUrl)
# $siteHostStatus = Get-UrlStatus -url $siteUrl -defaultHeader $defaultHeader
# Write-Host "Host status: $siteHostStatus"
# if ($siteHostStatus -ne 200)
# {
#     Write-Error "Failed to connect to $siteUrl get HttpStatus $siteHostStatus"
#     Write-Host "##vso[task.logissue type=error]Failed to connect to $siteUrl get HttpStatus $siteHostStatus"
#     return 1
# }


if ($null -eq $userAgent -or $userAgent.Length -eq 0){
    $userAgent = "CheckWebsite"
}

$list = New-Object 'System.Collections.Generic.List[TestResult]'

$totalStopwatch = [Diagnostics.Stopwatch]::StartNew()
$totalStopwatch.Start()

# Load spider
#[Reflection.Assembly]::LoadFile("$PSScriptRoot\Spider.dll")
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
    Write-Warning $testErrorDescription
    $testResult.Error = $true
    $testResult.Description = $testErrorDescription
    $siteUrl = "https://erroneous.com"
} else {
    $testResult.Error = $false
}
$testStopwatch.Stop()
$testResult.Time = $testStopwatch.Elapsed.TotalSeconds
$list.Add($testResult)
#-------------------------------------------------------

# Test connection to site
#-------------------------------------------------------
$testStopwatch = [Diagnostics.Stopwatch]::StartNew()
$testStopwatch.Start()

$testResult = [TestResult]::New();
$testResult.TestName = "Connection to site"
$baseUrlResult = $spider.PsCheckUrl($siteUrl, $userAgent)
#$url
if ($null -ne $baseUrlResult -and $baseUrlResult.Erroneous){
     $testResult.Error = $true
     $testResult.Description = "Connection to site failed. $($baseUrlResult.StatusCode) $($baseUrlResult.Description)"
}
$testStopwatch.Stop()
$testResult.Time = $testStopwatch.Elapsed.TotalSeconds
$list.Add($testResult)
#-------------------------------------------------------

# Expected SiteDomain
#-------------------------------------------------------
$testStopwatch = [Diagnostics.Stopwatch]::StartNew()
$testStopwatch.Start()

$testResult = [TestResult]::New();
$testResult.TestName = "Expect SiteDomain"
if ($null -ne $baseUrlResult -and $baseUrlResult.IsSiteDomain -eq $false){
     $testResult.Error = $true
     $testResult.Description = "Expected URL to be a SiteDomain 200. Example: https://yoursite.com. Not https://yoursite.com/something"
}
$testStopwatch.Stop()
$testResult.Time = $testStopwatch.Elapsed.TotalSeconds
$list.Add($testResult)
#-------------------------------------------------------

# Expected StatusCode 200
#-------------------------------------------------------
$testStopwatch = [Diagnostics.Stopwatch]::StartNew()
$testStopwatch.Start()

$testResult = [TestResult]::New();
$testResult.TestName = "Expect StatusCode 200"
if ($null -ne $baseUrlResult -and $baseUrlResult.StatusCode -ne 200){
     $testResult.Error = $true
     $testResult.Description = "Expected status 200. Actual: $($baseUrlResult.StatusCode) $($baseUrlResult.Description)"
}
$testStopwatch.Stop()
$testResult.Time = $testStopwatch.Elapsed.TotalSeconds
$list.Add($testResult)
#-------------------------------------------------------

# Expected result quicker then 1000 ms
#-------------------------------------------------------
$testStopwatch = [Diagnostics.Stopwatch]::StartNew()
$testStopwatch.Start()

$testResult = [TestResult]::New();
$testResult.TestName = "Expect response less than 1000 ms"
if ($null -ne $baseUrlResult -and $baseUrlResult.Time -gt 999){
     $testResult.Error = $true
     $testResult.Description = "Expected response less than 1000 ms. Actual: $($baseUrlResult.Time)"
}
$testStopwatch.Stop()
$testResult.Time = $testStopwatch.Elapsed.TotalSeconds
$list.Add($testResult)
#-------------------------------------------------------

# Check that a robots.txt exist
#-------------------------------------------------------
$testStopwatch = [Diagnostics.Stopwatch]::StartNew()
$testStopwatch.Start()

$testResult = [TestResult]::New();
$testResult.TestName = "robots.txt exist"

if ($true -eq $baseUrlResult.IsSiteDomain) {
    # We need to pimp the url and get the robots.txt
    $robotsTxtUrl = $spider.CreateRobotsTxtUrl($siteUrl)
    
    #$sitemapLink = [Spider.Sitemap]::GetSitemapUrlFromRobotsTxt($robotsTxtUrl)
} else {
    $testResult.Error = $true
    $testResult.Description = "Can not check robots.txt. You did not provide with SiteDomain."
}

$testStopwatch.Stop()
$testResult.Time = $testStopwatch.Elapsed.TotalSeconds
$list.Add($testResult)
#-------------------------------------------------------


$totalStopwatch.Stop()
$testTimerSeconds = $totalStopwatch.Elapsed.TotalSeconds

$testResultFileName = "TEST-CheckEpiserverWebsite_€hostname_result_€dateTime.xml"
PrintGenericTestResultXml -testResultFileName $testResultFileName -testResultList $list -baseUrl $siteUrl -testTimerSeconds $testTimerSeconds -filePath $resultFilePath
