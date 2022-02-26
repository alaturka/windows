function getGitDescription($dir) {
    if (!(Test-Path -Path $dir -PathType Container)) {
        throw (_ 'Directory not found: {0}' $dir)
    }

    Push-Location $dir
    try {
        $version = git describe --always --long 2>$null | capture
    }
    finally {
        Pop-Location
    }

    if ([String]::IsNullOrWhiteSpace($version)) {
        return 'UNRELEASED'
    }

    $version
}
