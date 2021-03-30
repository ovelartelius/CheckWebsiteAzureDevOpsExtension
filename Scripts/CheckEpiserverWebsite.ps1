Set-StrictMode -Version Latest
. E:\dev\CheckWebsiteAzureDevOpsExtension\Modules\LolCheckWebsiteUtil.ps1

[Reflection.Assembly]::LoadFile("E:\dev\CheckWebsiteAzureDevOpsExtension\Modules\Spider.dll")

$siteUrl = "http://mobelstu+dion.see"
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


$totalStopwatch.Stop()
$testTimerSeconds = $totalStopwatch.Elapsed.TotalSeconds

$testResultFileName = "TEST-CheckEpiserverWebsite_€hostname_result_€dateTime.xml"
PrintGenericTestResultXml -testResultFileName $testResultFileName -testResultList $list -baseUrl $siteUrl -testTimerSeconds $testTimerSeconds -filePath $resultFilePath
