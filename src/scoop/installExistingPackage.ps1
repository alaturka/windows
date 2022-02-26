function installExistingPackage- {
    param (
        [Parameter(Mandatory)] [string] $name,
        [Parameter(Mandatory)] [string] $package,
                               [string] $command
    )

    $step = (_ 'Installing {0}' $name)

    if (testHasPackage $package) {
        $step = (_ 'Updating {0}' $package)
        willdo($step)

        exec -MessageFailure (_ 'Package update failed: {0}' $package) scoop update $package
    } elseif (($PSBoundParameters.Keys -contains 'command') -and !(testHasCommand $command)) {
        willdo($step)

        exec -MessageFailure (_ 'Package installation failed: {0}' $package) scoop install $package
    } else {
        wontdo($step)
        return $false
    }

    $true
}

function installExistingPackage { [void](installExistingPackage- @args) }
