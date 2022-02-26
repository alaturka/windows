function installMissingPackage- {
    param (
        [Parameter(Mandatory)] [string] $name,
        [Parameter(Mandatory)] [string] $package,
                               [string] $command,
                               [switch] $ignore,
                               [switch] $repair
    )

    $step = (_ 'Installing {0}' $name)

    if (($PSBoundParameters.Keys -contains 'command') -and (testHasCommand $command)) {
        wontdo($step)
        return $false
    }

    if (testHasPackage $package) {
        if ($repair) {
            if (trueexec scoop prefix $package) {
                wontdo($step)
                return $false
            }

            Write-Verbose (_ 'Uninstalling package: {0}' $package)

            safeexec -MessageFailure (_ 'Package uninstallation failed: {0}' $package) scoop uninstall $package
        } else {
            wontdo($step)
            return $false
        }
    }

    willdo($step)

    exec -MessageFailure (_ 'Package installation failed: {0}' $package) scoop install $package

    $true
}

function installMissingPackage { [void](installMissingPackage- @args) }
