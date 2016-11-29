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

Describe 'License Notices' {

    $projectRoot = Join-Path $PSScriptRoot .. -Resolve
    $licenseFilePath = Join-Path $projectRoot 'LICENSE' -Resolve
    
    $noticeLines = Get-Content -Path $licenseFilePath -Tail 11 |
                        ForEach-Object { $_ -replace '^   ','' } |
                        Select-Object -First 13
    $noticeLines | Write-Verbose
    
    $filesToSkip = @(
                        '*.dll',
                        '*.dll-*',
                        '*.pdb',
                        '*.user',
                        '*.zip',
                        '*.exe',
                        '*.msi',
                        '*.orig',
                        '*.snk',
                        '*.json',
                        'nunit.framework.xml',
                        'LibGit2Sharp.xml',
                        '*.cer',
                        '*.md',
                        'LICENSE',
                        '*.help.txt',
                        'RELEASE_NOTES.md',
                        'NOTICE',
                        '*.sln',
                        '*.pfx',
                        'task*.xml',
                        '*.vdproj',
                        '*.csproj',
                        '*.nupkg',
                        '*.pshproj',
                        '*.nuspec',
                        'Publish-Carbon.ps1',
                        '*.so',
                        '*.dylib',
                        '*.git*',
                        '*.html',
                        'CNAME',
                        '*.css',
                        'LibGit2Sharp.dll.config',
                        'packages.config',
                        'repositories.config',
                        '*.props',
                        'libgit2.license.txt',
                        'libgit2_filename.txt',
                        'libgit2_hash.txt'
                    )
    
    [object[]]$filesMissingLicense = Get-ChildItem -Path $projectRoot -Exclude 'packages' |
        Get-ChildItem -Recurse -File -Exclude $filesToSkip |
        Where-Object { $_.FullName -notlike '*\obj\*' -and $_.FullName -notmatch '\\(packages|Carbon|Pester|Silk)\\' } |
        Where-Object { $name = $_.Name; -not ($filesToSkip | Where-Object { $name -like $_ }) } |
        ForEach-Object {
            $fileInfo = $_
            $file = Get-Content $fileInfo.FullName -Raw
            if( -not $file )
            {
                $fileInfo.FullName
                return
            }

            $ok = switch -Regex ( $fileInfo.Extension )
            {
                '^\.ps(m|d)*1$'
                {
                    $expectedNotice = $noticeLines -join ('{0}# ' -f ([Environment]::NewLine))
                    $expectedNotice = '# {0}' -f $expectedNotice
                    if( $file.StartsWith('<#') )
                    {
                        $file.Contains( $expectedNotice )
                    }
                    else
                    {
                        $file.StartsWith( $expectedNotice )
                    }
                    break
                }
                '^\.cs$'
                {
                    $expectedNotice = $noticeLines -join ('{0}// ' -f ([Environment]::NewLine))
                    $expectedNotice = '// {0}' -f $noticeLines
                    $file.StartsWith( $expectedNotice )
                    break
                }
                '^\.(ps1xml|csproj)$'
                {
                    $expectedNotice = $noticeLines -join ('{0}   ' -f ([Environment]::NewLine))
                    $expectedNotice = '<?xml version="1.0" encoding="utf-8"?>{0}<!--{0}   {1}{0}-->{0}' -f ([Environment]::NewLine),$expectedNotice
                    $file.StartsWith( $expectedNotice )
                    break
                }
                '^\.nuspec$'
                {
                    $expectedNotice = $noticeLines -join ('{0}   ' -f ([Environment]::NewLine))
                    $expectedNotice = '<?xml version="1.0"?>{0}<!--{0}   {1}{0}-->{0}' -f ([Environment]::NewLine),$expectedNotice
                    $file.StartsWith( $expectedNotice )
                    break
                }
                '^\.html$'
                {
                    $expectedNotice = $noticeLines -join ('{0}   ' -f ([Environment]::NewLine))
                    $expectedNotice = '<!--{0}   {1}{0}-->{0}' -f ([Environment]::NewLine),$expectedNotice
                    $file.StartsWith( $expectedNotice )
                    break
                }
                '^\.mof$'
                {
                    $expectedNotice = $noticeLines -join [Environment]::NewLine
                    $expectedNotice = '/*{0}{1}{0}*/' -f ([Environment]::NewLine),$expectedNotice
                    $file.StartsWith( $expectedNotice )
                    break
                }
                default
                {
                    Write-Verbose -Verbose $fileInfo.FullName
                    $false
                    break
                }
            }
            if( -not $ok )
            {
                Write-Debug -Message $fileInfo.FullName
                $fileInfo.FullName
            }
        }
    
    It 'should have a license notice in all files' {
        if( $filesMissingLicense )
        {
            ,$filesMissingLicense | Should BeNullOrEmpty
        }
    }
}
