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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-LibGit2Test.ps1' -Resolve)

Describe 'Receive-GitChange when ran from an outdated branch'{
    Clear-Error

    $remoteRepo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $remoteRepo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file1') -RepoRoot $remoteRepo
    Save-GitChange -RepoRoot $remoteRepo -Message 'file1 commit'

    $localRepoPath = Join-Path -Path (Resolve-TestDrivePath) -ChildPath 'LocalRepo'
    Copy-GitRepository -Source $remoteRepo -DestinationPath $localRepoPath

    Add-GitTestFile -RepoRoot $remoteRepo -Path 'file2'
    Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file2') -RepoRoot $remoteRepo
    Save-GitChange -RepoRoot $remoteRepo -Message 'file2 commit'

    $repo = Find-GitRepository -Path $localRepoPath
    try{
        $filter = New-Object LibGit2Sharp.CommitFilter
        $currentBranch = $repo.Head.Name
        $filter.Since = $repo.Branches["remotes/origin/$currentBranch"]
        $filter.Until = $repo.Branches[$currentBranch]

        $repo.Commits.QueryBy($filter) | Measure-Object | Select-Object -ExpandProperty Count | Should Be 0

        Receive-GitChange -RepoRoot $localRepoPath

        It 'should fetch remote changes for that branch'{        
            # Update the filter with fetched changes
            $filter.Since = $repo.Branches["remotes/origin/$currentBranch"]
            $filter.Until = $repo.Branches[$currentBranch]
            $repo.Commits.QueryBy($filter) | Measure-Object | Select-Object -ExpandProperty Count | Should BeGreaterThan 0
        }

    }
    finally{
        $repo.Dispose()
    }
   
    Assert-ThereAreNoErrors
}

Describe 'Receive-GitChange when ran from a repo with multiple branches'{
    Clear-Error

    $remoteRepo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $remoteRepo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file1') -RepoRoot $remoteRepo
    Save-GitChange -RepoRoot $remoteRepo -Message 'file1 commit'

    # Create another branch on remote
    $repo = Find-GitRepository -Path $remoteRepo
    try
    {
        $newBranch = $repo.Branches.Add("branch-2", "HEAD")
        $checkoutOptions = New-Object LibGit2Sharp.CheckoutOptions
        $repo.Checkout($newBranch, $checkoutOptions)

        # Clone local repo
        $localRepoPath = Join-Path -Path (Resolve-TestDrivePath) -ChildPath 'LocalRepo'
        Copy-GitRepository -Source $remoteRepo -DestinationPath $localRepoPath

        # Make remote changes on branch-2
        Add-GitTestFile -RepoRoot $remoteRepo -Path 'file3'
        Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file3') -RepoRoot $remoteRepo
        Save-GitChange -RepoRoot $remoteRepo -Message 'file3 on branch-2'

        # Switch back to master and fetch all remotes
        $localRepo = Find-GitRepository -Path $localRepoPath

        $masterBranch = $localRepo.Branches.Add("master", "remotes/origin/master")
        $localRepo.Checkout($masterBranch, $checkoutOptions)

        Receive-GitChange -RepoRoot $localRepoPath    

        It 'should fetch remote changes for all branches' {
            $filter = New-Object LibGit2Sharp.CommitFilter
            $filter.Since = $localRepo.Branches["remotes/origin/branch-2"]
            $filter.Until = $localRepo.Branches["branch-2"]

            $repo.Commits.QueryBy($filter) | Measure-Object | Select-Object -ExpandProperty Count | Should BeGreaterThan 0
        }
    }
    finally
    {
        $localRepo.Dispose()
        $repo.Dispose()
    }
   
    Assert-ThereAreNoErrors
}

Describe 'Receive-GitChange when there are multiple remotes for the repo' {
    Clear-Error
    # create remote orign
    $remoteRepo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $remoteRepo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file1') -RepoRoot $remoteRepo
    Save-GitChange -RepoRoot $remoteRepo -Message 'file1 commit'

    # create additional remote
    $remoteRepo2 = Join-Path -Path (Resolve-TestDrivePath) -ChildPath 'RemoteRepo2'
    Copy-GitRepository -Source $remoteRepo -DestinationPath $remoteRepo2

    # Clone local repo
    $localRepoPath = Join-Path -Path (Resolve-TestDrivePath) -ChildPath 'LocalRepo'
    Copy-GitRepository -Source $remoteRepo -DestinationPath $localRepoPath

    $repo = Find-GitRepository -Path $localRepoPath -Verify
    try
    {
        # Add remote to local repo
        $remoteRepo2Path = ('file:///{0}' -f $remoteRepo2.Replace('\','/'))
        $repo.Network.Remotes.Add('remote2', $remoteRepo2Path)

        # Make changes in both remotes
        Add-GitTestFile -RepoRoot $remoteRepo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file2') -RepoRoot $remoteRepo
        Save-GitChange -RepoRoot $remoteRepo -Message 'file2 commit'

        Add-GitTestFile -RepoRoot $remoteRepo2 -Path 'file3'
        Add-GitItem -Path (Join-Path -Path $remoteRepo2 -ChildPath 'file3') -RepoRoot $remoteRepo2
        Save-GitChange -RepoRoot $remoteRepo2 -Message 'file3 commit'

        Receive-GitChange -RepoRoot $localRepoPath -All

        It 'should fetch changes from all remotes'{
            $filter = New-Object LibGit2Sharp.CommitFilter
            $filter.Since = $repo.Branches["remotes/origin/master"]
            $filter.Until = $repo.Branches["master"]
            $repo.Commits.QueryBy($filter) | Measure-Object | Select-Object -ExpandProperty Count | Should BeGreaterThan 0

            $filter.Since = $repo.Branches["remotes/remote2/master"]
            $filter.Until = $repo.Branches["master"]
            $repo.Commits.QueryBy($filter) | Measure-Object | Select-Object -ExpandProperty Count | Should BeGreaterThan 0
        }

    }
    finally
    {
        $repo.Dispose()
    }
    Assert-ThereAreNoErrors
}

Describe 'Receive-GitChange when the given repo doesn''t exist' {
    Clear-Error

    Receive-GitChange -RepoRoot 'C:\I\do\not\exist' -ErrorAction SilentlyContinue
    It 'should write an error' {
        $Global:Error.Count | Should Be 1
        $Global:Error | Should Match 'does not exist'
    }
}