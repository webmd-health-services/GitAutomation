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

if (-not (Test-Path -Path 'variable:IsWindows'))
{
    $script:IsWindows = $true
    $script:IsLinux = $false
    $script:IsMacOS = $false
}

$oldLibGit2Sharp =
    [AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.FullName -like 'LibGit2Sharp*' } |
    ForEach-Object { $_.GetName() } |
    Where-Object { $_.Name -eq 'LibGit2Sharp' -and $_.Version -lt [version]'0.31.0' }
if( $oldLibGit2Sharp )
{
    $msg = 'Unable to load GitAutomation because an older version is loaded. Please restart PowerShell.'
    Write-Error -Message $msg -ErrorAction Stop
}

$moduleDirPath = $PSScriptRoot

$frameworkDirName = 'net8.0'
if (-not $PSVersionTable['PSEdition'] -or $PSVersionTable['PSEdition'] -eq 'Desktop')
{
    $frameworkDirName = 'net472'
}

$binDirPath = Join-Path -Path $moduleDirPath -ChildPath 'bin' -Resolve -ErrorAction Stop
$binDirPath = Join-Path -Path $binDirPath -ChildPath $frameworkDirName -Resolve -ErrorAction Stop

Add-Type -Path (Join-Path -Path $binDirPath -ChildPath 'LibGit2Sharp.dll' -Resolve -ErrorAction Stop)
Add-Type -Path (Join-Path -Path $binDirPath -ChildPath 'Git.Automation.dll' -Resolve -ErrorAction Stop)

$sshCmdPath = ''
$sshCmd = Get-Command -Name 'ssh' -ErrorAction Ignore
if ($sshCmd)
{
    $sshCmdPath = $sshCmd.Source
}

# Prefer Git for Windows if it is installed.
if ($IsWindows)
{
    $gitCmd = Get-Command -Name 'git.exe' -ErrorAction Ignore
    $gitSshCmdPath = ''
    if ($gitCmd)
    {
        $gitSshCmdPath = Split-Path -Path $gitCmd.Path -Parent
        $gitSshCmdPath = Join-Path -Path $gitSshCmdPath -ChildPath '..\usr\bin\ssh.exe' -Resolve -ErrorAction Ignore
    }

    if ($gitSshCmdPath)
    {
        $sshCmdPath = $gitSshCmdPath
    }
}

if ($sshCmdPath)
{
    [Git.Automation.SshExeTransport]::Unregister()
    Write-Verbose "Registering SSH transport with command ""${sshCmdPath}""."
    [Git.Automation.SshExeTransport]::Register($sshCmdPath)
}
else
{
    $msg =  "SSH support is unavailable because the ""ssh"" command does not exist."
    if ($IsWindows)
    {
        $msg += " Consider installing Git for Windows to get SSH support."
    }
    Write-Verbose -Message $msg
}

Join-Path -Path $PSScriptRoot -ChildPath 'Functions' |
    Where-Object { Test-Path -Path $_ -PathType Container } |
    Get-ChildItem -Filter '*.ps1' |
    ForEach-Object { . $_.FullName }
