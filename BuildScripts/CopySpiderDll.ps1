
Write-Host "---Start---"

$script = (Get-Item -Path .\Modules\Newtonsoft.Json.dll).FullName
$srcRootPath = (Get-Item .\* | Where-Object {$_.FullName.EndsWith("src")})
$dir = Get-ChildItem -Path $srcRootPath -Directory
foreach ($d in $dir){
    $psmodulesPath = Join-Path -Path $d.FullName -ChildPath "ps_modules"
    $filePath = $d.FullName
    
    if (Test-Path $psmodulesPath){
        Write-Host "Copy $script to $filePath"
        Copy-Item -Path $script -Destination $filePath -Recurse -Force
    }
}

$script = (Get-Item -Path .\Modules\Spider.dll).FullName
$srcRootPath = (Get-Item .\* | Where-Object {$_.FullName.EndsWith("src")})
$dir = Get-ChildItem -Path $srcRootPath -Directory
foreach ($d in $dir){
    $psmodulesPath = Join-Path -Path $d.FullName -ChildPath "ps_modules"
    $filePath = $d.FullName
    
    if (Test-Path $psmodulesPath){
        Write-Host "Copy $script to $filePath"
        Copy-Item -Path $script -Destination $filePath -Recurse -Force
    }
}

Write-Host "---End---"