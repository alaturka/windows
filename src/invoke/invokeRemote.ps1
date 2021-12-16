function invokeRemote {
    param (
        [Parameter(Mandatory)] [string] $url,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )

    Write-Verbose $url

    try {
        Set-StrictMode -Off

        # Set TLS1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 'Tls12'
        & $([scriptblock]::Create((Invoke-RestMethod $url))) @remainings
    }
    catch {
        Write-Verbose "$_"
        throw (_ 'Invocation from remote failed: {0}' $url)
    }
}

function urlrun { invokeRemote @args }
