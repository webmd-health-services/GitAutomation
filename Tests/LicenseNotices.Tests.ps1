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

Set-StrictMode -Version 'Latest'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\Glob' -Resolve)

Describe 'License Notices' {

    $projectRoot = Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve
    $licenseFilePath = Join-Path -Path $projectRoot -ChildPath 'LICENSE' -Resolve

    $noticeLines =
        Get-Content -Path $licenseFilePath -Tail 11 |
        ForEach-Object {
            $line = $_.Trim()
            if ($line)
            {
                [regex]::Escape($line)
            }
        }

    $licenseNoticeRegex = '(?s){0}' -f ($noticeLines -join ('.+'))

    # $DebugPreference = 'Continue'
    $licenseNoticeRegex | Write-Debug

    $pathsToIgnore = @(
        'GitAutomation/bin/**',
        'GitAutomation/en-us/**',
        'GitAutomation/packages/**',
        'Source/packages/**',
        'Source/Git.Automation/bin/**',
        'Source/Git.Automation/obj/**',
        '.github/**',
        '.output/**',
        '.vscode/**',
        'packages/**',
        'PSModules/**',
        '**/*.dll',
        '**/*.dll.config',
        '**/*.pdb',
        '**/*.md',
        '**/*.sln',
        '**/*.csproj',
        '**/packages.config',
        '.gitignore',
        'build.ps1',
        'NOTICE',
        '*.json',
        'whiskey.yml',
        'GitAutomation/NOTICE',
        'GitAutomation/LICENSE',
        '.dotnet/**'
    )

    [object[]]$filesMissingLicense =
        Find-GlobFile -Path $projectRoot -Exclude $pathsToIgnore |
        ForEach-Object {
            $fileInfo = $_
            $file = Get-Content -Path $fileInfo.FullName -Raw

            if( (-not $file) -or ($file -notmatch $licenseNoticeRegex))
            {
                $fileInfo.FullName
            }
        }

    It 'should have a license notice in all files' {
        $filesMissingLicense | Should -BeNullOrEmpty
    }
}
