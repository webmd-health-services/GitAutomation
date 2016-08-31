<#
.SYNOPSIS
Imports the LibGit2 module.

.DESCRIPTION
The `Import-LibGit2.ps1` script imports the `LibGit2` module from this script's directory.
#>
[CmdletBinding()]
param(
)

#Requires -Version 2
Set-StrictMode -Version 'Latest'
$PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2.psd1') -Force