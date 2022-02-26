function testGitRepository($dir) {
    if (!(Test-Path -Path $dir)) {
        return $false
    }

    Push-Location $dir
    try {
        [void](git rev-parse --verify HEAD *>$null); $exitCode = $LastExitCode
    }
    finally {
        Pop-Location
    }

    $exitCode -eq 0
}
