function resolveGitRepository($path) {
    if (!(testHasCommand 'git')) { return $null }

    $dir = if (Test-Path -Path $dir -PathType Leaf) { dirname($path) } else { $path }

    Push-Location $dir
    try {
        $result = git rev-parse --show-toplevel 2>$null | capture
    }
    finally {
        Pop-Location
    }

    $result
}
