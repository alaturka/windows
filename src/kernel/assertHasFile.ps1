function assertHasFile {
    param (
        [Parameter(Mandatory)] [string] $file,
                               [string] $message
    )

    if (!($PSBoundParameters.Keys -contains 'message')) {
        $message = (_ 'File not found: {0}' $file)
    }

    if (Test-Path -Path $file -PathType Leaf) {
        return
    }

    throw $message
}
