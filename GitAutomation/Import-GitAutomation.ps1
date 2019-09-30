<#
.SYNOPSIS
Imports the GitAutomation module.

.DESCRIPTION
The `Import-GitAutomation.ps1` script imports the `GitAutomation` module from this script's directory.
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

#Requires -Version 4
Set-StrictMode -Version 'Latest'

$originalVerbosePref = $Global:VerbosePreference
$originalWhatIfPref = $Global:WhatIfPreference

$Global:VerbosePreference = $VerbosePreference = 'SilentlyContinue'
$Global:WhatIfPreference = $WhatIfPreference = $false

try
{
    if( (Get-Module -Name 'GitAutomation') )
    {
        Remove-Module -Name 'GitAutomation' -Force
    }

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'GitAutomation.psd1')
}
finally
{
    $Global:VerbosePreference = $originalVerbosePref
    $Global:WhatIfPreference = $originalWhatIfPref
}