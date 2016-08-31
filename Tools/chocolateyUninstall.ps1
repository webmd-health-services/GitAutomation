<#
.SYNOPSIS
Chocolately install script for Carbon.
#>
[CmdletBinding()]
param(
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

$env:PSModulePath -split ';' |
    Join-Path -ChildPath 'LibGit2' |
    Where-Object { Test-Path -Path $_ -PathType Container } |
    Rename-Item -NewName { 'LibGit2{0}' -f [IO.Path]::GetRandomFileName() } -PassThru |
    Remove-Item -Recurse -Force
