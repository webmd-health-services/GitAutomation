# 0.2.0

 * Added `Set-GitConfiguration` for setting Git configuration variables. Implements the `git config` command.
 * Added SSH support. You must have an `ssh.exe` program in your path.
 

# 0.1.1 (9 September 2016)

 * Fixed: NuGet, Chocolatey, and PowerShell Gallery packages are missing assemblies.


# 0.1.0 (9 September 2016)

 * Created `Add-GitItem` function for promoting new, untracked, and modified files/directories to the Git staging area so they can be committed. Implements the `git add` command.
 * Created `Get-GitRepository` function for getting an object representing a repository.
 * Created `Save-GitChange` function for commiting changes to a repository. Implements the `git commit` command.
 * Created `Find-GitRepository` function for searching a directory and its parents (i.e. up it tree) for a Git repository.
 * Created `New-GitRepository` function for creating new Git repositories.
 * Created `Get-GitRepositoryStatus` function for getting the state of a repository's working directory and any items staged for the next commit.

 
# 0.0.0 (31 August 2016)

 * Created `Copy-GitRepository` function for cloning Git repositories.

