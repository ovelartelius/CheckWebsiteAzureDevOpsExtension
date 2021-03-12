function Test-RequestSpecUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $requestSpec,
        [Parameter(Mandatory = $true)]
        [bool] $hide200result
    )
    $swUrl = [Diagnostics.Stopwatch]::StartNew()
    $swUrl.Start()
    try {
        $requestHeaders = $requestSpec[1]
        $requestUrl = $requestSpec[0]
          if ([string]::IsNullOrEmpty($requestHeaders)) {
              $response = Invoke-WebRequest -Uri $requestUrl -UseBasicParsing -Verbose:$false -MaximumRedirection 1
          } else {
              $response = Invoke-WebRequest -Uri $requestUrl -Headers $requestHeaders -UseBasicParsing -Verbose:$false -MaximumRedirection 1
          }
          $swUrl.Stop()
          $statusCode = $response.StatusCode
          $seconds = $swUrl.Elapsed.TotalSeconds
          if ($statusCode -eq 200) {
            if ($hide200result -ne $true){
                $statusDescription = $response.StatusDescription
                Write-Host "$requestUrl => Status: $statusCode $statusDescription in $seconds seconds" -ForegroundColor Black -BackgroundColor Green
              }
          } else {
              Write-Warning "$requestUrl => Error $statusCode after $seconds seconds"
          }
      }
      catch {
          $swUrl.Stop()
          $statusCode = $_.Exception.Response.StatusCode.value__
          $errorMessage = $_.Exception.Message
          $seconds = $swUrl.Elapsed.TotalSeconds
          if ($statusCode -eq 500) {
            Write-Host "$requestUrl => Error $statusCode after $seconds seconds: $errorMessage" -BackgroundColor Red
          }
          else {
            Write-Host "$requestUrl => Error $statusCode after $seconds seconds: $errorMessage" -ForegroundColor Black -BackgroundColor Yellow
          }
      }
      return $statusCode
}