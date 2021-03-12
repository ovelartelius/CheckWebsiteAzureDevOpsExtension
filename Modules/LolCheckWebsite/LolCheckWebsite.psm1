<#


.DESCRIPTION
    Functions that are used to test websites.
#>

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

# $functionpath = $PSScriptRoot + "\functions\"

# $functionlist = Get-ChildItem -Path $functionpath -Name

# foreach ($function in $functionlist)
# {
#     . ($functionpath + $function)
# }


Set-StrictMode -Version Latest
# Get public and private function definition files.

$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)

$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files.
foreach ($import in @($Public + $Private)) {
    try {
        Write-Verbose "Importing $($import.FullName)"        . $import.FullName
    } catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

## Export all of the public functions making them available to the user
foreach ($file in $Public) {
    Export-ModuleMember -Function $file.BaseName
}