function assertWSLReady {
    # Build 18362 or higher required for WSL2.
    # Build 18980 or higher required to change username in WSL box.

    $build = 18980
    if ([System.Environment]::OSVersion.Version.Build -lt $build) {
        notice (_ 'YOUR SYSTEM MEETS THE MINIMUM REQUIREMENTS FOR WSL AND, THE INSTALLATION WILL CONTINUE.')
        notice (_ 'FOR A BETTER WSL EXPERIENCE, UPGRADING TO A MORE LATEST VERSION OF WINDOWS IS RECOMMENDED.')
        notice ''
    }
}
