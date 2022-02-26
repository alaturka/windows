function testIsURLLocalAndPresent($url, $dir) {
    $path = urlpath($url)
    if ($path) {
        $local = [IO.Path]::GetFullPath($dir)
        if ($path -eq $local) {
            return $true
        }
    }

    $false
}

# Adapted from Scoop source: https://github.com/ScoopInstaller/Scoop
function initializeGitRepository {
    param (
        [Parameter(Mandatory, Position = 0)] [string] $url,
        [Parameter(Mandatory, Position = 1)] [string] $dir,
                                             [string] $branch
    )

    if (testIsURLLocalAndPresent $url $dir) {
        Write-Verbose (_ 'Skip cloning as the repository seems local: {0}' $url)
        return
    }

    if (Test-Path -Path $dir) {
        throw (_ 'Clone target directory already exists: {0}' $dir)
    }

    $flags = @(
        '--quiet', '--single-branch'
    )

    $cloneDesc = "$url"
    if (![String]::IsNullOrWhiteSpace($branch) -and ($branch -ne '.')) {
        $flags += (
            '--branch', $branch
        )
        $cloneDesc = "$url [$branch]"
    }

    getting (_ 'Cloning repository: {0}' $cloneDesc)
    exec -- git clone @flags $url "`"$($dir)`""

    if ($LastExitCode -ne 0) { rmrf $dir }

    if (!(Test-Path -Path $dir)) {
        throw (_ 'Cloning repository failed: {0}' $cloneDesc)
    }
}
