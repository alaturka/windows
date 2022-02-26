function resolveLFH {
    param (
        [Parameter(Mandatory)] [string] $root,
                               [switch] $dot,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )

    $root = fullpath($root)

    $lfhRoot = if ($dot) {
        [IO.Path]::Combine($root, '.local')
    } else {
        [IO.Path]::Combine($root, 'local')
    }

    [IO.Path]::Combine([string[]](@($lfhRoot) + $remainings))
}
