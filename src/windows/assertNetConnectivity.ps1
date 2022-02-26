function assertNetConnectivity {
    $ProgressPreferenceSave    = $Global:ProgressPreference
    $Global:ProgressPreference = 'SilentlyContinue'

    Write-Verbose (_ 'Checking network connectivity...')

    if (!(Test-NetConnection github.com -InformationLevel Quiet)) {
        throw (_ 'NETWORK CONNECTION REQUIRED')
    }

    $Global:ProgressPreference = $ProgressPreferenceSave
}
