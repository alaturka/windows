function assertHasDir {
    param (
        [Parameter(Mandatory)] [string] $dir,
                               [string] $message
    )

    if (!($PSBoundParameters.Keys -contains 'message')) {
        $message = (_ 'Directory not found: {0}' $dir)
    }

    if (Test-Path -Path $dir -PathType Container) {
        return
    }

    throw $message
}
