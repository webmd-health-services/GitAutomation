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

#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-LibGit2Test.ps1' -Resolve)

function Assert-ConfigurationVariableSet
{
    param(
        $Path
    )

    It 'should set the configuraton variable' {
        Get-Content -Path $Path | Where-Object { $_ -match 'autocrlf\ =\ false' } | Should Not BeNullOrEmpty
    }
}

Describe 'Set-GitConfiguration when setting the current repository''s configuration' {
    $repo = New-GitTestRepo
    Push-Location -Path $repo
    try
    {
        Set-GitConfiguration -Name 'core.autocrlf' -Value 'false'
        Assert-ConfigurationVariableSet -Path '.git\config'
    }
    finally
    {
        Pop-Location
    }
}

Describe 'Set-GitConfiguration when setting a specific repository''s configuration' {
    $repo = New-GitTestRepo

    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -RepoRoot $repo
    Assert-ConfigurationVariableSet -Path (Join-Path -Path $repo -ChildPath '.git\config')
}

Describe 'Set-GitConfiguration when repo does not exist' {
    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -RepoRoot (Get-Item -Path 'TestDrive:').FullName -ErrorVariable 'errors' -ErrorAction SilentlyContinue
    It 'should write an error' {
        $errors | Should Match 'not in a Git repository'
    }
}

Describe 'Set-GitConfiguration when setting global configuration' {
    $value = [Guid]::NewGuid()
    Set-GitConfiguration -Name 'libgit2.test' -Value $value -Scope Global
    $repo = Find-GitRepository -Path $PSScriptRoot
    It 'should set option globally' {
        $option = $repo.Config | Where-Object { $_.Key -eq 'libgit2.test' -and $_.Value -eq $value -and $_.Level -eq [LibGit2Sharp.ConfigurationLevel]::Global } | Should Not BeNullOrEmpty
    }
}

Describe 'Set-GitConfiguration when setting a specific repository''s configuration and current directory is a sub-directory of the repository root' {
    $repo = New-GitTestRepo
    Push-Location -Path $repo
    try
    {
        New-Item -Path 'child' -ItemType 'Directory' 
        Set-Location -Path 'child'

        Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -ErrorVariable 'errors'
        Assert-ConfigurationVariableSet -Path '..\.git\config'
        It 'should not write any errors' {
            $errors | Should BeNullOrEmpty
        }
    }
    finally
    {
        Pop-Location
    }
}