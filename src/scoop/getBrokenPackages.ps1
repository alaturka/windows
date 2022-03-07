function getBrokenPackages {
    $installed = Get-ChildItem -Directory $(Join-Path $HOME 'scoop' | Join-Path -ChildPath 'apps') -Name

    foreach ($package in $installed) {
        if ($package -eq 'scoop') { continue }

        scoop info $package *>$null
        if (($LastExitCode -ne 0) -or @(scoop info $package 6>$null | Select-String -pattern 'Installed: No').Count -eq 1) {
            $package
        }
    }
}
