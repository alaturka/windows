function getGitRelease($repository) {
    $version = git -C $repository describe --always --long 2>$null | capture

    if ([String]::IsNullOrWhiteSpace($version)) {
        return 'UNRELEASED'
    }

    $version
}
