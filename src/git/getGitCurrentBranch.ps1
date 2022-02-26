function getGitCurrentBranch($dir) {
    if (!(Test-Path -Path $dir -PathType Container)) {
        throw (_ 'Directory not found: {0}' $dir)
    }

    Push-Location $dir
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null | capture
    }
    finally {
        Pop-Location
    }

    $branch
}
