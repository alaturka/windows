# Adapted from Scoop source: https://github.com/ScoopInstaller/Scoop
function initializeGitRepository($source) {
    if (Test-Path -Path $source.Path) {
        throw (_ 'Repository exists: {0}' $source.Path)
    }

    git clone -q $source.URL --branch $source.Branch --single-branch "`"$($source.Path)`""

    if ($LastExitCode -ne 0) { rmrf $source.Path }

    if (!(Test-Path $source.Path)) {
        throw (_ 'Cloning repository failed: {0}' $source.URL)
    }
}
