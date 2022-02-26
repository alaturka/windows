function syncSelf {
    if (!$PSScriptRoot -or !(testGitRepository $PSScriptRoot)) {
        Write-Warning (_ 'No repository found for self')
        return
    }

    safecall -MessageFailure (_ 'Self updating failed') { syncGitRepository $PSScriptRoot }
}
