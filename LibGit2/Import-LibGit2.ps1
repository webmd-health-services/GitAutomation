<#
.SYNOPSIS
Imports the LibGit2 module.

.DESCRIPTION
The `Import-LibGit2.ps1` script imports the `LibGit2` module from this script's directory.
#>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[CmdletBinding()]
param(
)

#Requires -Version 2
Set-StrictMode -Version 'Latest'
$PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2.psd1') -Force