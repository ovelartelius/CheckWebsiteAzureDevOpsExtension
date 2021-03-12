#Remove-Module -Name "LolCheckWebsite" -Verbose
#Remove-Module -Name "Az.Storage" -Verbose
#Import-Module -Name E:\dev\CheckWebsiteAzureDevOpsExtension\Modules\LolCheckWebsite -Verbose

. E:\dev\CheckWebsiteAzureDevOpsExtension\Modules\LolCheckWebsiteUtil.ps1
#. E:\dev\ps-scripts\dxp-deployment\DxpProjects.ps1

[Reflection.Assembly]::LoadFile("E:\dev\CheckWebsiteAzureDevOpsExtension\Modules\Spider.dll")

# $checkUrlManifest = new-object Spider.Models.CheckUrlManifest
# $checkUrlManifest.Url = "https://seb.no"
# $checkUrlManifest.SourceUrls = new-object List<string>
# $checkUrlManifest.UserAgent = "TestOve"

$spider = new-object Spider.Spider

$siteUrl = "https://seb.no/"

# Validate the site URL
$validUrl = $spider.ValidateUrl($siteUrl)
if ($false -eq $validUrl) {
    Write-Error "Provided URL $siteUrl is not a valid URI."
    return 1
}

# Test connection to the site.
$validUrl = $spider.ValidateUrlOnSite($siteUrl)
$siteHostStatus = Get-UrlStatus -url $siteUrl -defaultHeader $defaultHeader
Write-Host "Host status: $siteHostStatus"
if ($siteHostStatus -ne 200)
{
    Write-Error "Failed to connect to $siteUrl get HttpStatus $siteHostStatus"
    Write-Host "##vso[task.logissue type=error]Failed to connect to $siteUrl get HttpStatus $siteHostStatus"
    return 1
}




#$siteHostStatus = Get-UrlStatus -url $siteUrl -defaultHeader $defaultHeader
# Write-Host "Host status: $siteHostStatus"
# if ($siteHostStatus -ne 200)
# {
#     Write-Error "Failed to connect to $siteUrl get HttpStatus $siteHostStatus"
#     Write-Host "##vso[task.logissue type=error]Failed to connect to $siteUrl get HttpStatus $siteHostStatus"
#     return 1
# }

$sitemapUrl = [Spider.Sitemap]::GetSitemapUrlFromRobotsTxt("https://seb.no/robots.txt")
$sitemapUrl


#$status = Get-UrlStatus -Url "https://seb.no"
#$status
