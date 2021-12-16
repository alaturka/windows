function testGitRepository($repository) {
    if (!(Test-Path -Path $repository)) {
        return $false
    }

    if (!(Test-Path -Path "$repository\.git")) {
        return $false
    }

    [void](git -C $repository rev-parse --verify HEAD *>$null); $LastExitCode -eq 0
}
