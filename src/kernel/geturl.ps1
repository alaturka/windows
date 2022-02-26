function geturl($url) {
    getting "$url"

    $path = urlpath($url)
    if ($path) {
        if (Test-Path -Path $path -PathType Leaf) {
            return (Get-Content -Path $path -Raw)
        } elseif (Test-Path -Path $path) {
            throw (_ 'Not a file: {0}' $url)
        } else {
            throw (_ 'File not found: {0}' $url)
        }
    }

    try {
        (Invoke-WebRequest -UseBasicParsing -Uri $url).Content
    } catch {
        $status = $_.Exception.Response.StatusCode.Value__
        if ($status -eq '404') {
            throw (_ 'URL not found: {0}' $url)
        } else {
            Write-Warning "$_"
            throw (_ 'Getting from remote failed: {0}' $url)
        }
    }
}
