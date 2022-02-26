function urlpath($url) {
    # Dots are special
    if (@('.', '..').Contains($url)) { return [IO.Path]::GetFullPath($url) }

    try {
        $parsed = [System.Uri]$url
        if ($($parsed | Select-Object -ExpandProperty Scheme) -eq 'file') {
            return [IO.Path]::GetFullPath($($parsed | Select-Object -ExpandProperty LocalPath))
        }
    }
    catch {
        Write-Verbose (_ 'Malformed URL: {0}' $url)
    }

    $null
}


