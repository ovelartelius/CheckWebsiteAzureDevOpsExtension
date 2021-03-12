function Get-UrlStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Url,
        
        [Parameter(Mandatory = $false)]
        [object] $defaultHeader
    )
    $swUrl = [Diagnostics.Stopwatch]::StartNew()
    $swUrl.Start()
    try {
        if ([string]::IsNullOrEmpty($defaultHeader)) {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -Verbose:$false -MaximumRedirection 2
        } else {
            $response = Invoke-WebRequest -Uri $Url -Headers $defaultHeader -UseBasicParsing -Verbose:$false -MaximumRedirection 2
        }
        $swUrl.Stop()
        $statusCode = $response.StatusCode
        $seconds = $swUrl.Elapsed.TotalSeconds
        if ($statusCode -eq 200) {
            if ($hide200result -ne $true){
                $statusDescription = $response.StatusDescription
                Write-Host "$Url => Status: $statusCode $statusDescription in $seconds seconds" -ForegroundColor Black -BackgroundColor Green
            } else {
                Write-Warning "$Url => Error $statusCode after $seconds seconds"
            }
        }
      }
      catch {
            $swUrl.Stop()
            $statusCode = $_.Exception.Response.StatusCode.value__
            $errorMessage = $_.Exception.Message
            $seconds = $swUrl.Elapsed.TotalSeconds
            if ($statusCode -eq 500) {
                Write-Host "$Url => Error $statusCode after $seconds seconds: $errorMessage" -BackgroundColor Red
            }
            elseif ($statusCode -eq 301) {
                Write-Host "$Url => Error $statusCode after $seconds seconds: $errorMessage" -ForegroundColor Black -BackgroundColor Yellow
                $response
            }
            else {
                Write-Host "$Url => Error $statusCode after $seconds seconds: $errorMessage" -ForegroundColor Black -BackgroundColor Yellow
            }
      }
      return $statusCode
}