
# GitAutomation PowerShell Module Changelog

## 1.0.0

* Adding support for PowerShell (pwsh).
* Minimum .NET Framework version is now 4.7.2.
* Updating dependencies:
  * LibGitSharp 0.26.1 to 0.31.0
  * LibGit2Sharp.NativeLibraries 2.0.289 to 2.0.323
  * libgit2 0.28.3 to 1.8.4
* Fixed: `Set-GitConfiguration` and `Remove-GitConfiguration` threw exceptions if attempting to set config at scopes
  that don't have any configured locations or don't exist. They now instead write non-terminating errors.

## 0.14.0

> Released 30 Sep 2019

* Added a verbose message to `Remove-GitConfiguration`
* Fixing typo in about_GitAutomation_Installation help topic.
* `Import-GitAutomation.ps1` no longer shows `Import-Module` and `Remove-Module` verbose messages.
* Upgrading to LibGitSharp 0.26.1 (from 0.24.0). GitAutomation now requires .NET Framework 4.6 or later.

## 0.13.0

> Released 9 Apr 2019

* Fixed: `ConvertTo-GitFullPath` doesn't properly encode the returned Uri string. (thanks @thorbenw)
* Added `Credential` parameter to the `Receive-GitCommit` function. (thanks @thorbenw)

## 0.12.0

> Released 30 Oct 2018

* Added `Get-GitConfiguration` function for getting Git configuration values.
* Added `Remove-GitConfiguration` function for removing/unsetting Git configuration values.

## 0.11.0

> Released 17 Apr 2018

***This release contains breaking changes.*** The *Upgrade Instructions* section below explains what you should do when
upgrading.

## Changes

* ***Breaking Change***: Module renamed to `GitAutomation`. The LibGit2 folks don't want us to use the LibGit2 name.
* Added `Force` switch to `Update-GitRepository` to overwrite any uncomitted changes when checking out/updating to a
  specific revision.
* ***Breaking Change***: Removed `Test-GitIncomingCommit` function. It actually downloaded changes from the remote
  repository to do its test. This function only exists because we came from Mercurial, which doesn't do any kind of
  automated merging. Because of this, it is normal to have to test/check for incoming changes when automating. Git does
  automatic mergeing so this kind of check isn't needed.
* ***Breaking Change***: Removed `Test-GitOutgoingCommit` function.  This function only exists because we came from
  Mercurial, which doesn't do any kind of automated merging. Because of this, it is normal to have to test/check for
  outgoing changes. With Git, it just handles no outgoing/upstream changes to push, so this function isn't necessary.
* Added a `Sync-GitBranch` function for pulling (i.e. downloading) and merging a remote branch into its local branch.
  This function implements the `git pull` command.
* ***Breaking Change***: `Receive-GitCommit` no longer merges changes into branches. It only downloads new commits into
  a repository. Use the new `Sync-GitBranch` to pull and merge changes from a remote branch into your current branch.
* ***Breaking Change***: Removed the `Fetch` switch from `Receive-GitCommit`; the function now only fetches so the
  switch was redundant.s
* Added `Send-GitBranch` function for pushing a branch to a remote repository, merging in any new changes, if possible.
* ***Breaking Change***: Renamed `Save-GitChange` to `Save-GitCommit` for better discoverability and consistency.

## Upgrade Instructions

* The namespace for compiled objects is now `Git.Automation`. Replace references in your code to `LibGit2.Automation`
  with `Git.Automation`.
* Remove any usages of the `Test-GitIncomingCommit` or `Test-GitOutgoingCommit` functions.
* Replace any usages of `Receive-GitCommit` that don't have the `Fetch` parameter with `Sync-GitBranch`.
* Remove usages of the `Fetch` switch when calling `Receive-GitCommit`.
* Replace all usages of `Save-GitChange` with `Save-GitCommit`.

## 0.10.1

> Released 22 Mar 2018

Fixed: File missing from package on the PowerShell Gallery.

## 0.10.0

> Released 19 Mar 2018

* Added `Test-GitCommit` function for testing if a commit exists.
* Added `Send-GitObject` function for sending local objects to remote repositories.
* `New-GitRepository` can now create bare repositories. Use the new `Bare` switch.
* `Send-GitCommit` can now setup tracking information so that remote branches are setup to track new local branches. Use
  the `SetUpstream` switch.
* Fixed: `Save-GitChange` fails when `RepoRoot` parameter is empty and committer information is read from Git's
  configuration files.

## 0.9.2

> Released 7 Mar 2018

* Automated publishing works.
* Changed author and copyright metadata.

## 0.9.1

> Released 7 Mar 2018

* Fixed: publishing to nuget.org fails.
* Fixed: Chocolatey package is missing VERIFICATION.txt.

## 0.9.0

> Released 7 Mar 2018

* Upgraded to LibGit2 0.24.0. This is a potential breaking change. We noticed the following changes:
  * The `LibGit2Sharp.TreeChanges` object returned by `Compare-GitTree` returns new objects types for its `Added`,
    `Deleted`, `Modified`, `TypeChanged`, `Renamed`, `Copied`, `Unmodified`, and `Conflicted` properties. They used to
    be `List` objects, but now they are strictly `IEnumerable`.
  * The `LibGit2Sharp.FileStatus` no longer has `Added`, `Staged`, `Removed`, `StagedTypeChange`, `Untracked`,
    `Modified`, `Missing`, or `TypeChanged` values. This affects the object returned by `Get-GitRepositoryStatus`.
  * The `Since` property on `LibGit2Sharp.CommitFilter` is gone, replaced with `IncludeReachableFrom`.
  * The `Until` property on `LibGit2Sharp.CommitFilter` is gone, replaced with `ExcludeReachableFrom`.
  * The `Name` property on `LibGit2Sharp.Branch` is gone, replaced with `FriendlyName`.
* Fixed: `Get-GitCommit` doesn't return all commits when using the `-All` switch; it only returns commits reachable from
  the current HEAD.
* Added `Merge-GitCommit` function for merging branches, tags, commits, etc.
* Added `New-GitSignature` function for creating author signatures, which are used when committing to record the
  commit's author.
* Added `Signature` parameter to `Save-GitChange` so you can customize the author information for a commit. By default,
  `Save-GitChange` reads author information from Git's global configuration files.

## 0.8.0

> Released 7 Nov 2017

 * `Update-GitRepository` now supports checking out branches that exist at the remote origin, but don't yet exist locally.

## 0.7.0

> Released 27 Oct 2017

 * `Compare-GitTree` now accepts either a path to the repository with the `RepositoryRoot` parameter or a repository object with the `RepositoryObject` parameter.

## 0.6.0

> Released 25 Oct 2017

 * Added functionality to `Get-GitCommit` for getting a list of commits between two specified commits.

## 0.5.0

> Released 23 Oct 2017

 * Added: `Compare-GitTree` function for getting a `[LibGit2Sharp.TreeChanges]` object representing changes to the repository file tree between two commits.

## 0.4.0

> Released 19 Oct 2017

 * Added: `Send-GitCommit` function for pushing local commits to upstream remote repositories.

 ## 0.3.2

 > Released 6 Apr 2017

 * Fixed: `Copy-GitRepository` intermittently fails when using SSH.
 * Fixed: `Copy-GitRepository` takes an order of magnitude longer than normal Git because it updates the clone's progress too frequently. It now only updates progress every 1/10th of a second, which has minimal impact on clone speed.

## 0.3.1

> Released 30 Dec 2016

 * Fixed: `Get-GitTag` leaked memory and didn't clean up after itself properly.

## 0.3.0

> Released 13 Dec 2016

 * Added `Get-GitCommit` function for getting commits.
 * Added `Test-GitOutgoingCommit` function for checking if there are outgoing changes.
 * Added `Test-GitUncommmittedChange` function for checking if there are any uncommitted changes in a repository.
 * Added `Receive-GitCommit` function for pulling/fetching changes into a repository from a remote repository.
 * Added `Test-GitRemoteUri` function for testing if a URI points to a Git repository.
 * Added `Test-GitIncomingCommit` function for testing if there are incoming/unpulled/unfetched commits.
 * Added `Get-GitBranch` function for getting the branches in a repository.
 * Added `New-GitBranch` function for creating a new branch in a repository.
 * Added `Test-GitBranch` function for testing if a branch exists in a repository.
 * Added `Get-GitTag` function for getting the tags in a repository.
 * Added `New-GitTag` function for creating tags in a repository.
 * Added `Test-GitTag` function for testing if a tag exists in a repository.
 * Added `Update-GitRepository` for updating a repository to a commit, branch, tag, etc, i.e. for checking out a specific commit.

## 0.2.0

> Released 4 Nov 2016

 * Added `Set-GitConfiguration` for setting Git configuration variables. Implements the `git config` command.
 * Added SSH support. You must have an `ssh.exe` program in your path.

## 0.1.1

> Released 9 Sep 2016

 * Fixed: NuGet, Chocolatey, and PowerShell Gallery packages are missing assemblies.

## 0.1.0

> Released 9 Sep 2016

 * Created `Add-GitItem` function for promoting new, untracked, and modified files/directories to the Git staging area so they can be committed. Implements the `git add` command.
 * Created `Get-GitRepository` function for getting an object representing a repository.
 * Created `Save-GitCommit` function for commiting changes to a repository. Implements the `git commit` command.
 * Created `Find-GitRepository` function for searching a directory and its parents (i.e. up it tree) for a Git repository.
 * Created `New-GitRepository` function for creating new Git repositories.
 * Created `Get-GitRepositoryStatus` function for getting the state of a repository's working directory and any items staged for the next commit.

## 0.0.0

> Released 31 Aug 2016

 * Created `Copy-GitRepository` function for cloning Git repositories.
