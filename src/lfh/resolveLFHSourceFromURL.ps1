function resolveLFHSourceFromURL {
    param (
        [Parameter(Mandatory)] [string] $url,
        [Parameter(Mandatory)] [string] $root,
                               [switch] $dot,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )

    $src = $url -replace '^[^/]+:/+' -replace '(/+|[.]git)$' -replace '/', "`\"

    $slug  = @('src', $src)
    $slug += $remainings

    resolveLFH -Root $root -Dot:$dot @slug
}
