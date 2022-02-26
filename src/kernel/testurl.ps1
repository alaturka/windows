function testurl {
    param (
        [Parameter(Mandatory)] [string] $url,
                               [int]    $timeout = 10,
                               [int[]]  $successCodes = @(200, 301, 302)
    )

    $path = urlpath($url)
    if ($path -and (Test-Path -Path $path)) {
        return $true
    }

    try {
         $param = @{
             DisableKeepAlive = $true
             ErrorAction      = 'Stop'
             Method           = 'Head'
             TimeoutSec       = $timeout
             Uri              = $url
             UseBasicParsing  = $true
             Verbose          = $false
        }

        $response = Invoke-WebRequest @param

        if ($successCodes.Contains([int]$response.StatusCode)) { return $true }
    } catch {
        $status = $_.Exception.Response.StatusCode.Value__

        if ($status -eq '404') {
            Write-Verbose (_ 'URL not found: {0}' $url)
        } else {
            Write-Verbose "$_"
        }
    }

    Write-Verbose (_ 'Getting from remote failed: {0}' $url)

    $false
}
