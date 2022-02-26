function assertHasCommand {
    param (
        [Parameter(Mandatory)] [string] $name,
                               [string] $message
    )

    if (!($PSBoundParameters.Keys -contains 'message')) {
        $message = (_ 'Command required: {0}' $name)
    }

    if (testHasCommand($name)) {
        return
    }

    throw $message
}
