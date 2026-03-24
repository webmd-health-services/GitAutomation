
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\Glob' -Resolve)
}

Describe 'License Notices' {
    It 'has license notice in all published files' {
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
            '.dotnet/**',
            'GitAutomation/Functions/**',
            'appveyor.yml'
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

        $filesMissingLicense | Should -BeNullOrEmpty
    }
}
