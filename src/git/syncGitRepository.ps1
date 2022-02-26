# Adapted from Scoop source: https://github.com/ScoopInstaller/Scoop
function syncGitRepository {
    param (
        [Parameter(Mandatory, Position = 0)] [string] $dir,
                                             [string] $url,
                                             [string] $branch
    )

    if (!(Test-Path -Path $dir)) {
        throw (_ 'Directory not found: {0}' $dir)
    }

    Push-Location $dir

    if (!(testGitRepository $dir)) {
        throw (_ 'Not inside a valid repository: {0}' $dir)
    }

    try {
        $type = exec -- git config --local --default='exact' --get 'sync.type' | capture
        if ($type -eq 'never') {
            Write-Verbose (_ 'Skip syncing due to the sync type: {0}' $type)
            return
        }

        $isUrlChanged = if ($PSBoundParameters.Keys -contains 'url') {
            $currentUrl = exec -- git config remote.origin.url | capture
            $url -ne $currentUrl
        } else {
            $false
        }

        $currentBranch = exec -- git rev-parse --abbrev-ref HEAD | capture

        $isBranchChanged = if (($PSBoundParameters.Keys -contains 'branch') -and ($branch -ne '.')) {
            $branch -ne $currentBranch
        } else {
            $branch = $currentBranch
            $false
        }

        $commitBeforeUpdate = exec -- git rev-parse HEAD | capture

        getting (_ 'Updating repository {0}' $dir)

        # Fetch and reset local source if the source or the branch is changed
        if ($isUrlChanged -or $isBranchChanged) {
            # Change remote URL if the source is changed
            if ($isUrlChanged) { exec -- git config remote.origin.url $url }

            # Reset git fetch refs, so that it can fetch all branches (GH-3368)
            exec -- git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
            # Fetch remote branch
            exec -- git fetch --force origin "refs/heads/`"$($branch)`":refs/remotes/origin/$($branch)" --quiet
            # Checkout and track the branch
            exec -- git checkout -B $branch -t origin/$branch --quiet
            # Reset branch HEAD
            exec -- git reset --hard origin/$branch --quiet
        } else {
            exec -- git fetch --force origin --quiet
            # Reset branch HEAD
            exec -- git reset --hard origin/$branch --quiet
        }

        if (!($type -eq 'exact')) { exec -- git clean -xdf --quiet }

        $commitAfterUpdate = exec -- git rev-parse HEAD | capture

        if ($commitBeforeUpdate -ne $commitAfterUpdate) {
            Write-Verbose (_ 'Changes found')
        } else {
            Write-Verbose (_ 'No changes found')
        }

        if ($VerbosePreference -eq 'Continue') {
            $format = 'tformat: * %C(yellow)%h%Creset %<|(72,trunc)%s %C(cyan)%cr%Creset'
            exec -- git --no-pager log --no-decorate --format=$format "$commitBeforeUpdate..HEAD"
        }
    }
    finally {
        Pop-Location
    }
}
