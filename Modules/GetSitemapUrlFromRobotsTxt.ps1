#Remove-Module -Name "LolCheckWebsite" -Verbose
#Remove-Module -Name "Az.Storage" -Verbose
#Import-Module -Name E:\dev\CheckWebsiteAzureDevOpsExtension\Modules\LolCheckWebsite -Verbose

. E:\dev\CheckWebsiteAzureDevOpsExtension\Modules\LolCheckWebsiteUtil.ps1
#. E:\dev\ps-scripts\dxp-deployment\DxpProjects.ps1

#[Reflection.Assembly]::LoadFile("E:\dev\CheckWebsiteAzureDevOpsExtension\Modules\Spider.dll")
[Reflection.Assembly]::LoadFile("Spider.dll")

# $checkUrlManifest = new-object Spider.Models.CheckUrlManifest
# $checkUrlManifest.Url = "https://seb.no"
# $checkUrlManifest.SourceUrls = new-object List<string>
# $checkUrlManifest.UserAgent = "TestOve"

# $spider = new-object Spider.Spider

# $checkUrlResult = $spider.CheckUrl($checkUrlManifest)
# $checkUrlResult

$sitemapUrl = [Spider.Sitemap]::GetSitemapUrlFromRobotsTxt("https://seb.no/robots.txt")
$sitemapUrl


#$status = Get-UrlStatus -Url "https://seb.no"
#$status
