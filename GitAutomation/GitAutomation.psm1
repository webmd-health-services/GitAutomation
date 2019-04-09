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

$registeredSsh = $false
$gitCmd = Get-Command -Name 'git.exe' -ErrorAction Ignore
if( $gitCmd )
{
    $sshExePath = Split-Path -Path $gitCmd.Path -Parent
    $sshExePath = Join-Path -Path $sshExePath -ChildPath '..\usr\bin\ssh.exe' -Resolve -ErrorAction Ignore
    if( $sshExePath )
    {
       [Git.Automation.SshExeTransport]::Unregister()
       [Git.Automation.SshExeTransport]::Register($sshExePath)
       $registeredSsh = $true
    }
}

if( -not $registeredSsh )
{
    Write-Warning -Message 'SSH support is disabled. To enable SSH, please install Git for Windows. GitAutomation uses the version of SSH that ships with Git for Windows.'
}

Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Functions' -Resolve) -Filter '*.ps1' |
    Where-Object { $_.Name -notlike '*.Tests.ps1' } |
    ForEach-Object { . $_.FullName }
