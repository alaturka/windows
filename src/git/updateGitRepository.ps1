# Adapted from Scoop source: https://github.com/ScoopInstaller/Scoop
function updateGitRepository($source) {
    if (!(Test-Path -Path "$($source.Path)\.git")) {
        throw (_ 'Repository not exists: {0}' $source.Path)
    }

    Push-Location $source.Path

    $previousCommit  = git rev-parse HEAD | capture
    $currentURL      = git config remote.origin.url | capture
    $currentBranch   = git branch | capture

    $isURLChanged    = ![String]::IsNullOrWhiteSpace($source.URL) -and
                       !($currentURL -Match $source.URL)
    $isBranchChanged = ![String]::IsNullOrWhiteSpace($source.Branch) -and
                       !($currentBranch -Match "\*\s+$($source.Branch)")

    # Change remote URL if the source is changed
    if ($isURLChanged) {
        git config remote.origin.url $source.URL
    }

    # Fetch and reset local source if the source or the branch is changed
    if ($isURLChanged -or $isBranchChanged) {
        # Reset git fetch refs, so that it can fetch all branches (GH-3368)
        git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
        # Fetch remote branch
        git fetch --force origin "refs/heads/`"$($source.Branch)`":refs/remotes/origin/$($source.Branch)" -q
        # Checkout and track the branch
        git checkout -B $source.Branch -t origin/$source.Branch -q
        # Reset branch HEAD
        git reset --hard origin/$source.Branch -q
    } else {
        git pull --rebase=false -q
    }

    if ($LastExitCode -ne 0) { throw (_ 'Updating repository failed: {0}' $currentURL) }

    Pop-Location
}
