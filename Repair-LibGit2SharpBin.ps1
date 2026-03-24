[CmdletBinding()]
param(
)

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'
$InformationPreference = 'Continue'

Get-ChildItem -Path '.\GitAutomation\bin\net8.0\runtimes\' -Directory |
    Copy-Item -Recurse -Destination '.\GitAutomation\bin\net8.0' -Force -Verbose

foreach ($lib in (Get-ChildItem -Path '.\GitAutomation\bin\net8.0\*\native\*' -File))
{
    $newParent = $lib.Directory.Parent.FullName
    Write-Information "Moving $($lib.FullName) to ${newParent}."
    $lib | Move-Item -Destination $newParent -Force
    Write-Information "Removing $($lib.Directory.FullName)."
    $lib.Directory | Remove-Item -Recurse
}

foreach ($lib in (Get-ChildItem -Path '.\GitAutomation\bin\net8.0\linux-*\*','.\GitAutomation\bin\net8.0\osx-*\*' -File))
{
    $newLibName = $lib.Name -replace '^lib',''
    $newLibPath = Join-Path -Path $lib.Directory -ChildPath $newLibName
    if (Test-Path -Path $newLibPath)
    {
        Write-Information "Removing ${newLibPath}."
        Remove-Item -Path $newLibPath
        continue
    }

    Write-Information "Renaming ""$($lib.FullName)"" to ${newLibName}."
    $lib | Rename-Item -NewName $newLibName -Force
}