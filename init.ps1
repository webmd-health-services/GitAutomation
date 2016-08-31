
Set-StrictMode -Version 'Latest'

$PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition

$carbonVersion = '2.2.0'
$libGit2SharpVersion = '0.22.0'
$libGit2SharpNativeVersion = '1.0.129'
$pesterVersion = '3.4.3'
$packagesRoot = Join-Path -Path $PSScriptRoot -ChildPath 'packages'

$nugetExePath = Join-Path -Path $PSScriptRoot -ChildPath '.\Tools\NuGet\nuget.exe' -Resolve
& $nugetExePath install 'LibGit2Sharp.NativeBinaries' -Version $libGit2SharpNativeVersion -OutputDirectory $packagesRoot
& $nugetExePath install 'LibGit2Sharp' -Version $libGit2SharpVersion -OutputDirectory $packagesRoot
& $nugetExePath install 'Carbon' -Version $carbonVersion -OutputDirectory $packagesRoot
& $nugetExePath install 'Pester' -Version $pesterVersion -OutputDirectory $packagesRoot

& (Join-Path -Path $PSScriptRoot -ChildPath ('packages\Carbon.{0}\Carbon\Import-Carbon.ps1' -f $carbonVersion) -Resolve)

$binRoot = Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2\bin'
Install-Directory -Path $binRoot

Get-ChildItem -Path (Join-Path -Path $packagesRoot -ChildPath ('LibGit2Sharp.{0}\lib\net40' -f $libGit2SharpVersion)) |
    Copy-Item -Destination $binRoot

$nativeBinaryRoot = Join-Path -Path $binRoot -ChildPath 'NativeBinaries'
Install-Directory -Path $nativeBinaryRoot

$nativeBinaryLibRoot = Join-Path -Path $packagesRoot -ChildPath ('LibGit2Sharp.NativeBinaries.{0}\libgit2' -f $libGit2SharpNativeVersion)
@( 
    'linux',
    'osx',
    'windows\amd64',
    'windows\x86'
) | ForEach-Object {
    Copy-Item -Path (Join-Path -Path $nativeBinaryLibRoot -ChildPath $_) -Destination (Join-Path -Path $nativeBinaryRoot -ChildPath (Split-Path -Leaf -Path $_)) -Recurse -Force
}

Install-Junction -Link (Join-Path -Path $packagesRoot -ChildPath 'Pester') -Target (Join-Path -Path $packagesRoot -ChildPath ('Pester.{0}\tools' -f $pesterVersion))