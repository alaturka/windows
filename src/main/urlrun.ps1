function urlrun($url) {
    Write-Verbose $url

    try {
        Set-StrictMode -Off

        # Set TLS1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 'Tls12'
        & $([scriptblock]::Create((Invoke-RestMethod $url))) @args
    }
    catch {
        Write-Warning "$_"
        throw (_ 'Invocation from remote failed: {0}' $url)
    }
}
